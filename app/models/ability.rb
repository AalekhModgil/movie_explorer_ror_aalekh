class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new

    if user.is_a?(AdminUser)
      can :manage, :all
    elsif user.supervisor?
      can :manage, Movie
    else
      can :read, Movie
    end
  end
end