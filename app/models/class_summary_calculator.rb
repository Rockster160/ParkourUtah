class ClassSummaryCalculator
  attr_reader :summary

  # summary = ClassSummaryCalculator.new(start_date: start_date, end_date: end_date).generate

  CalculatedSummary = Struct.new(:start_date, :end_date, :days, :instructors, :total_earned, :total_payment, :profit) do
    def instructor_by_name(name)
      instructors.each do |instructor|
        return instructor if instructor.name == name
      end
    end
  end
  SummaryInstructor = Struct.new(:name, :class_instructors, :total_earned, :total_payment, :profit)
  SummaryDay = Struct.new(:date, :classes, :total_earned, :total_payment, :profit)
  DayClass = Struct.new(:schedule_id, :name, :instructors, :total_earned, :total_payment, :profit, :class_cancelled)
  ClassInstructor = Struct.new(:name, :students, :total_earned, :total_payment, :profit)
  InstructorStudent = Struct.new(:name, :payment_type, :payment_amount)

  def initialize(options={})
    now = DateTime.current.in_time_zone(Time.zone)
    start_date = options[:start_date] || now
    end_date = options[:end_date] || now
    raise InvalidDateFormat unless start_date.respond_to?(:to_datetime) && end_date.respond_to?(:to_datetime)
    start_date = start_date.to_datetime.beginning_of_day
    end_date = end_date.to_datetime.end_of_day
    raise InvalidDate unless start_date < end_date

    @summary = CalculatedSummary.new(start_date, end_date, [], [], 0, 0, 0)
  end

  def generate
    prefill_all_instructors
    calculate_days
    calculate_profits
    @summary
  end

  private

  def calculate_profits
    @summary.days.each do |day|
      day.classes.each do |event_class|
        event = EventSchedule.find(event_class.schedule_id)
        event_class.instructors.each do |instructor|
          summary_instructor = @summary.instructor_by_name(instructor.name)
          raise InstructorNotFound unless summary_instructor.present?

          minimum_to_pay_instructor = event.min_payment_per_session || 0
          payment_per_student = event.payment_per_student || 0
          maximum_to_pay_instructor = event.max_payment_per_session

          amount_to_pay_instructor = payment_per_student * instructor.students.count
          amount_to_pay_instructor = minimum_to_pay_instructor if amount_to_pay_instructor < minimum_to_pay_instructor
          amount_to_pay_instructor = maximum_to_pay_instructor if maximum_to_pay_instructor.present? && amount_to_pay_instructor > maximum_to_pay_instructor
          amount_to_pay_instructor = 0 if event_class.class_cancelled

          amount_earned = instructor.students.map(&:payment_amount).sum

          profit = amount_earned - amount_to_pay_instructor

          [instructor, summary_instructor, event_class, day, @summary].each do |object_to_increment|
            object_to_increment.total_earned += amount_earned
            object_to_increment.total_payment += amount_to_pay_instructor
            object_to_increment.profit += profit
          end
        end
      end
    end
  end

  def prefill_all_instructors
    User.instructors.each do |instructor|
      @summary.instructors << SummaryInstructor.new(instructor.full_name, [], 0, 0, 0)
    end
  end

  def calculate_days
    @summary.days = (@summary.start_date).upto(@summary.end_date).map do |date|
      summary_day = SummaryDay.new(date, [], 0, 0, 0)
      summary_day.classes = generate_classes_for_day(date)
      summary_day
    end
  end

  def generate_classes_for_day(date)
    events = EventSchedule.events_for_date(date)

    events.map do |event|
      generate_details_for_event(event)
    end
  end

  def generate_details_for_event(event)
    day_class = DayClass.new(event.event_schedule_id, event.title, [], 0, 0, 0, event.cancelled?)
    if event.attendances.none?
      class_instructor = ClassInstructor.new(event.host_name, [], 0, 0, 0)
      day_class.instructors << class_instructor
    else
      event.attendances.group_by(&:instructor_id).each do |instructor_id, attendances|
        instructor = User.instructors.find(instructor_id)

        class_instructor = ClassInstructor.new(instructor.full_name, [], 0, 0, 0)
        class_instructor.students = generate_students_by_event_and_attendances(event, attendances)

        day_class.instructors << class_instructor
      end
    end
    day_class
  end

  def generate_students_by_event_and_attendances(event, attendances)
    attendances.map do |attendance|
      athlete = attendance.athlete
      charge_type = attendance.type_of_charge.split(" ").first
      charge_amount = charge_type == "Credits" ? event.cost_in_dollars.round : 0

      InstructorStudent.new(athlete.full_name, charge_type, charge_amount)
    end
  end

end
