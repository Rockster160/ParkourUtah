class CreateAwsLogger < ActiveRecord::Migration[5.0]
  def change
    create_table :aws_loggers do |t|
      t.text :orginal_string
      t.string :bucket_owner
      t.string :bucket
      t.datetime :time
      t.string :remote_ip
      t.string :requester
      t.string :request_id
      t.string :operation
      t.string :key
      t.string :request_uri
      t.string :http_status
      t.string :error_code
      t.bigint :bytes_sent
      t.bigint :object_size
      t.bigint :total_time
      t.bigint :turn_around_time
      t.string :referrer
      t.string :user_agent
      t.string :version_id

      t.boolean :set_all_without_errors
    end
  end
end
