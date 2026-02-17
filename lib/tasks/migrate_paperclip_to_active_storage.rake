namespace :paperclip do
  desc "Migrate Paperclip Image attachments to ActiveStorage"
  task migrate_images: :environment do
    require 'aws-sdk-s3'

    s3 = Aws::S3::Resource.new(
      region: 'us-west-2',
      access_key_id: ENV['PKUT_AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['PKUT_AWS_SECRET_ACCESS_KEY']
    )
    bucket = s3.bucket(ENV['PKUT_S3_BUCKET_NAME'])

    # Paperclip stored images at: /images/files/:id_partition/:style/:filename
    # id_partition splits id into 3-char groups, e.g. id=1 => 000/000/001
    Image.find_each do |image|
      next if image.file.attached?

      # Paperclip columns on images table
      file_name = image[:file_file_name]
      content_type = image[:file_content_type]

      next unless file_name.present?

      id_partition = image.id.to_s.rjust(9, '0').scan(/.{3}/).join('/')
      key = "images/files/#{id_partition}/original/#{file_name}"

      begin
        obj = bucket.object(key)
        if obj.exists?
          temp = Tempfile.new([File.basename(file_name, '.*'), File.extname(file_name)])
          temp.binmode
          obj.get(response_target: temp.path)

          image.file.attach(
            io: File.open(temp.path),
            filename: file_name,
            content_type: content_type
          )
          puts "Migrated Image ##{image.id}: #{file_name}"
          temp.close!
        else
          puts "SKIP Image ##{image.id}: S3 object not found at #{key}"
        end
      rescue => e
        puts "ERROR Image ##{image.id}: #{e.message}"
      end
    end

    puts "Done migrating Paperclip images to ActiveStorage."
  end
end
