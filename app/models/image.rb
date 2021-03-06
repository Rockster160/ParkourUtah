# == Schema Information
#
# Table name: images
#
#  id         :integer          not null, primary key
#  spot_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Image < ApplicationRecord
  belongs_to :spot, optional: true

  has_attached_file :file,
               :styles => { :medium => "300x400>", :thumb => "120x160" },
               storage: :s3,
               s3_permissions: :private,
               bucket: ENV['PKUT_S3_BUCKET_NAME'],
               :default_url => "http://parkourutah.com/images/missing.png",
               :convert_options => { :all => '-background white -flatten +matte' }
  validates_attachment_content_type :file, :content_type => /\Aimage\/.*\Z/
end
