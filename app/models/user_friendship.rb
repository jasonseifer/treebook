class UserFriendship < ActiveRecord::Base
  belongs_to :user
  belongs_to :friend, class_name: 'User', foreign_key: 'friend_id'

  attr_accessible :user, :friend, :user_id, :friend_id, :state

  after_destroy :delete_mutual_friendship!

  state_machine :state, initial: :pending do
    after_transition on: :accept, do: [:send_acceptance_email, :accept_mutual_friendship!]
    after_transition on: :block, do: [:block_mutual_friendship!]

    state :requested
    state :blocked

    event :accept do
      transition any => :accepted
    end

    event :block do
      transition any => :blocked
    end
  end

  validate :not_blocked

  def self.request(user1, user2)
    transaction do
      friendship1 = create(user: user1, friend: user2, state: 'pending')
      friendship2 = create(user: user2, friend: user1, state: 'requested')

      friendship1.send_request_email if !friendship1.new_record?
      friendship1
    end
  end

  def not_blocked
    if UserFriendship.exists?(user_id: user_id, friend_id: friend_id, state: 'blocked') ||
       UserFriendship.exists?(user_id: friend_id, friend_id: user_id, state: 'blocked')
      errors.add(:base, "The friendship cannot be added.")
    end
  end

  def send_request_email
    UserNotifier.friend_requested(id).deliver
  end

  def send_acceptance_email
    UserNotifier.friend_request_accepted(id).deliver
  end

  def mutual_friendship
    self.class.where({user_id: friend_id, friend_id: user_id}).first
  end

  def accept_mutual_friendship!
    # Grab the mutal friendship and update the state without using
    # the state machine so as not to invoke callbacks.
    mutual_friendship.update_attribute(:state, 'accepted')
  end

  def delete_mutual_friendship!
    mutual_friendship.delete
  end

  def block_mutual_friendship!
    mutual_friendship.update_attribute(:state, 'blocked') if mutual_friendship
  end
end
