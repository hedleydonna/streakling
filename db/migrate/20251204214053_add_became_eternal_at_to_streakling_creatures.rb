class AddBecameEternalAtToStreaklingCreatures < ActiveRecord::Migration[7.1]
  def change
    add_column :streakling_creatures, :became_eternal_at, :date
  end
end
