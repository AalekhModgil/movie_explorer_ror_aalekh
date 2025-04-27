Rails.application.config.to_prepare do
  ActiveStorage::Attachment.class_eval do
    def self.ransackable_attributes(auth_object = nil)
      ["blob_id", "created_at", "id", "id_value", "name", "record_id", "record_type"]
    end
  end
end