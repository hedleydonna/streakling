class RenameNameFieldsAndAddDescription < ActiveRecord::Migration[7.0]
  def change
    # Rename habits.name to habits.habit_name
    rename_column :habits, :name, :habit_name

    # Add description to habits
    add_column :habits, :description, :text

    # Rename streakling_creatures.name to streakling_creatures.streakling_name
    rename_column :streakling_creatures, :name, :streakling_name
  end
end
