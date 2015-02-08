class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  def full_name
    "#{self.first_name.capitalize} #{self.last_name.capitalize}"
  end

  def is_mod?
    self.role > 0
  end

  def is_admin?
    self.role > 1
  end
end
