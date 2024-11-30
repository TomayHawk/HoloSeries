extends CanvasLayer

var item_buttons
var item_labels
var item_quantities

const item_names := [
    { # Consumables
        0: "Potion",
        1: "MAX Potion",
        2: "Phoenix Burger" ## ### include nexus items here
    },
    { # Equipments
        0: "Sword",
        1: "Shield",
        2: "Armor"
    },
    { # Key Items
        0: "Key1",
        1: "Key2",
        2: "Key3"
    }
]

func _ready():
    pass
    # for item_index in miscellaneous_buttons

func update_items(_inventory_index): # !#!# Consumables/Equipments/KeyItems
    for item_index in GlobalSettings.current_save["inventory"].size():
        item_quantities[item_index].text = str(GlobalSettings.current_save["inventory"][item_index]) ## ### ??????

func _on_inventory_type_button_pressed(extra_arg_0):
    print(item_names[extra_arg_0])
