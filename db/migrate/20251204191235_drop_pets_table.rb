class DropPetsTable < ActiveRecord::Migration[7.1]
  def change
    drop_table :pets
  end
end
