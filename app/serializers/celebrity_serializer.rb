class CelebritySerializer < ActiveModel::Serializer
  attributes :id, :name, :age, :birth_date, :nationality, :biography, :image_url
  has_many :movies

  def birth_date
    object.birth_date.to_s
  end

  def image_url
    object.image.attached? ? object.image.service.url(object.image.key, secure: true) : nil
  end
end