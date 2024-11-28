extends CanvasLayer

var miscellaneous_buttons
var miscellaneous_quantities

func _ready():
    pass
    # for item_index in miscellaneous_buttons

func update_items():
    for item_index in GlobalSettings.current_save["inventory"].size():
        miscellaneous_quantities[item_index].text = str(GlobalSettings.current_save["inventory"][item_index]) ## ### ??????