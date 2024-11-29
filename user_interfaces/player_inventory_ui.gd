extends CanvasLayer

var item_buttons
var item_labels
var item_quantities

const item_names := {
    0: "Potion",
    1: "MAX Potion",
    2: "Phoenix Burger"
}

func _ready():
    pass
    # for item_index in miscellaneous_buttons

func update_items(_inventory_index): # !#!# Consumables/Equipments/KeyItems
    for item_index in GlobalSettings.current_save["inventory"].size():
        item_quantities[item_index].text = str(GlobalSettings.current_save["inventory"][item_index]) ## ### ??????