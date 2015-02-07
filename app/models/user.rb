class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  # Scope -> .is_mod true if role == 1
  # Scope -> .is_admin true if role == 2

  def full_name
    "#{self.first_name} #{self.last_name}"
  end
end
