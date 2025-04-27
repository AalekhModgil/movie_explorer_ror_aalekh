class MovieSerializer < ActiveModel::Serializer
  attributes :id, :title, :genre, :release_year, :rating, :director, :duration, :description, :premium,:main_lead,:streaming_platform, :poster_url, :banner_url

  def poster_url
    if object.poster.attached?
      object.poster.service.url(object.poster.key, eager: true) 
    else
      nil
    end
  end

  def banner_url
    if object.banner.attached?
      object.banner.service.url(object.banner.key, eager: true)
    else
      nil
    end
  end
end