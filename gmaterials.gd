extends Node 

var m_day = load("res://assets/base_material.tres")
var m_night = load("res://assets/base_material_emission.tres")

func day_material():
	return m_day
	
func night_material():
	return m_night
