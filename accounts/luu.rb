# frozen_string_literal: true

# == Schema Information
#
# Table name: campaigns
#
#  id               :integer          not null, primary key
#  shop_id          :integer
#  name             :string
#  period_kind      :integer
#  is_active        :boolean          default(TRUE)
#  start_on         :date
#  end_on           :date
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  note             :text
#  start_segment_id :integer
#  end_segment_id   :integer
#
# Indexes
#
#  index_campaigns_on_end_segment_id    (end_segment_id)
#  index_campaigns_on_shop_id           (shop_id)
#  index_campaigns_on_start_segment_id  (start_segment_id)
#
# Foreign Keys
#
#  fk_rails_...  (end_segment_id => segments.id)
#  fk_rails_...  (start_segment_id => segments.id)
#

class Campaign < ActiveRecord::Base
  has_many :campaign_events
  has_many :campaign_histories
  has_many :campaign_excluded_histories

  belongs_to :shop
  belongs_to :start_segment, foreign_key: :start_segment_id,
    class_name: Segment.name
  belongs_to :end_segment, foreign_key: :end_segment_id,
    class_name: Segment.name

  enum period_kind: {regular: 1, temporary: 2}

  validates :period_kind, :shop, :name, :start_segment, presence: true
  validate :validate_end_on_after_start_on, if: ->{temporary?}
  validates :start_on_or_end_on, presence: true, if: ->{temporary?}
  validates :start_on, :end_on, absence: true, if: ->{regular?}

  scope :name_like, ->(name) do
    where("name LIKE :name", name: "%#{name}%")
  end

  scope :by_period_kind, ->(period_kinds) do
    where(period_kind: period_kinds)
  end

  scope :published, -> do
    condition = <<~EOS
      (campaigns.is_active = true) AND
      (
        (
          campaigns.period_kind = :regular
        ) OR
        (
          (campaigns.period_kind = :temporary) AND
          (
            (campaigns.start_on <= :date AND campaigns.end_on > :date) OR
            (campaigns.start_on <= :date AND campaigns.end_on IS NULL) OR
            (campaigns.start_on IS NULL AND campaigns.end_on > :date)
          )
        )
      )
    EOS
    where(condition, date: Date.current,
      regular: period_kinds[:regular], temporary: period_kinds[:temporary])
  end

  scope :unpublished, -> do
    where.not(id: published)
  end

  def published?
    self.class.published.where(id: id).exists?
  end

  def is_scenario_ready?
    return false if campaign_events.empty?
    campaign_events_sorted = campaign_events.sorted
    pre_campaign_event_ids = campaign_events_sorted.pluck :pre_campaign_event_id

    pre_campaign_event_ids.first.nil? &&
      pre_campaign_event_ids.drop(1) == campaign_events_sorted.ids[0..-2]
  end

  def publish!
    assign_attributes is_active: true
    # if temporary?
    #   if end_on && end_on <= Date.current
    #     assign_attributes start_on: Date.current, end_on: nil
    #   else
    #     assign_attributes start_on: Date.current
    #   end
    # end
    # save!
  end

  def unpublish!
    assign_attributes is_active: false
    # if temporary?
    #   if start_on && start_on > Date.current
    #     assign_attributes start_on: nil, end_on: Date.current
    #   else
    #     assign_attributes end_on: Date.current
    #   end
    # end
    # save!
  end

  def destroyable?
    campaign_histories.count.zero? && campaign_excluded_histories.count.zero?
  end

  private
  def validate_end_on_after_start_on
    return if start_on.blank? || end_on.blank? || start_on <= end_on
    errors.add :end_on, I18n.t("errors.messages.end_on_after_start_on")
  end

  def start_on_or_end_on
    start_on.presence || end_on.presence
  end
end
