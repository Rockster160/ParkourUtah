##
# Composable filter query for admin user exports.
#
# Add a new filter by:
#   1. Documenting its param key in `KNOWN_PARAMS` below
#   2. Adding a `where(...)` clause in one of the `filter_*` methods
#   3. Rendering a form field for the param in views/admin_exports/index.html.erb
class UserExportQuery

  KNOWN_PARAMS = [
    :signed_up_from,
    :signed_up_to,
    :can_receive_emails,
    :can_receive_sms,
    :signed_in_since,
    :never_signed_in,
    :attended_from,
    :attended_to,
    :min_attendances,
    :exclude_trials,
    :event_schedule_ids,
    :weekdays,
    :has_unlimited_access,
    :has_auto_renew,
    :has_active_plan,
    :max_youngest_athlete_age,
    :min_youngest_athlete_age,
    :min_credits,
  ].freeze

  # A PurchasedPlanItem confers unlimited class access when any `free_items`
  # entry has `count: 0` (per the plan_items form: "0 = unlimited") AND its
  # tags include one of the class-attendance tags.
  UNLIMITED_PLAN_SQL = <<~SQL.squish.freeze
    free_items IS NOT NULL
    AND jsonb_typeof(free_items) = 'array'
    AND EXISTS (
      SELECT 1 FROM jsonb_array_elements(free_items) AS elem
      WHERE (elem->>'count')::int = 0
        AND (elem->'tags') ?| ARRAY['class', 'classes']
    )
  SQL

  def initialize(params = {})
    @params = params || {}
  end

  def users
    scope = User.all
    scope = filter_account(scope)
    scope = filter_attendance(scope)
    scope = filter_membership(scope)
    scope = filter_athletes(scope)
    scope.order(:id)
  end

  def count
    users.count(:id)
  end

  def any_filter_present?
    KNOWN_PARAMS.any? { |k| present?(@params[k]) }
  end

  private

  def filter_account(scope)
    if (d = parse_date(:signed_up_from))
      scope = scope.where("users.created_at >= ?", d.beginning_of_day)
    end
    if (d = parse_date(:signed_up_to))
      scope = scope.where("users.created_at < ?", d.end_of_day)
    end
    scope = scope.where(can_receive_emails: true) if bool(:can_receive_emails)
    scope = scope.where(can_receive_sms: true)    if bool(:can_receive_sms)
    if (d = parse_date(:signed_in_since))
      scope = scope.where("users.last_sign_in_at >= ?", d.beginning_of_day)
    end
    scope = scope.where(last_sign_in_at: nil) if bool(:never_signed_in)
    if @params[:min_credits].to_s.present?
      scope = scope.where("users.credits >= ?", @params[:min_credits].to_i)
    end
    scope
  end

  def filter_attendance(scope)
    from = parse_date(:attended_from)
    to   = parse_date(:attended_to)
    min  = @params[:min_attendances].to_i
    schedule_ids = array(:event_schedule_ids).map(&:to_i).reject(&:zero?)
    weekdays_ints = array(:weekdays).map(&:to_i).select { |i| (0..6).cover?(i) }

    unless from || to || min > 0 || schedule_ids.any? || weekdays_ints.any? || bool(:exclude_trials)
      return scope
    end

    attendance_scope = Attendance.joins(:athlete).joins(event: :event_schedule)
    attendance_scope = attendance_scope.where("attendances.created_at >= ?", from.beginning_of_day) if from
    attendance_scope = attendance_scope.where("attendances.created_at < ?",  to.end_of_day)         if to
    attendance_scope = attendance_scope.where.not(type_of_charge: "Trial Class")                    if bool(:exclude_trials)
    attendance_scope = attendance_scope.where(event_schedules: { id: schedule_ids })                if schedule_ids.any?
    attendance_scope = attendance_scope.where(event_schedules: { day_of_week: weekdays_ints })      if weekdays_ints.any?

    grouped = attendance_scope.group("athletes.user_id")
    grouped = grouped.having("COUNT(attendances.id) >= ?", min) if min > 0
    scope.where(id: grouped.select("athletes.user_id"))
  end

  def filter_membership(scope)
    if bool(:has_unlimited_access)
      unlimited_via_subscription = RecurringSubscription.active.select(:user_id)
      unlimited_via_plan         = PurchasedPlanItem.active.where(UNLIMITED_PLAN_SQL).select(:user_id)
      scope = scope.where("users.id IN (?) OR users.id IN (?)", unlimited_via_subscription, unlimited_via_plan)
    end
    if bool(:has_auto_renew)
      renewing_subscription = RecurringSubscription.active.auto_renew.select(:user_id)
      renewing_plan         = PurchasedPlanItem.active.where(auto_renew: true).select(:user_id)
      scope = scope.where("users.id IN (?) OR users.id IN (?)", renewing_subscription, renewing_plan)
    end
    scope = scope.where(id: PurchasedPlanItem.active.select(:user_id)) if bool(:has_active_plan)
    scope
  end

  def filter_athletes(scope)
    max_age = @params[:max_youngest_athlete_age].to_s
    min_age = @params[:min_youngest_athlete_age].to_s
    return scope if max_age.blank? && min_age.blank?

    max_age_i = max_age.presence&.to_i
    min_age_i = min_age.presence&.to_i

    matching_ids = Athlete.where.not(user_id: nil).find_each.each_with_object(Set.new) do |a, set|
      age = a.age
      next unless age
      next if max_age_i && age > max_age_i
      next if min_age_i && age < min_age_i
      set << a.user_id
    end
    scope.where(id: matching_ids.to_a)
  end

  def bool(key)
    v = @params[key]
    v == true || v == "1" || v == "true"
  end

  def array(key)
    Array(@params[key]).reject { |v| v.to_s.blank? }
  end

  def parse_date(key)
    v = @params[key]
    return nil if v.blank?
    Time.zone.parse(v.to_s) rescue nil
  end

  def present?(v)
    return false if v.nil?
    return v.any? { |x| present?(x) } if v.is_a?(Array)
    v.to_s.present?
  end
end
