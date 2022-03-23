#!/usr/bin/env bash

## Author  : Rubén Cacio
## Mail    : rcaciocamacho@gmail.com
## Github  : rccamacho

theme_path="/home/$USER/.config/rofi/nord.rasi"
rofi_command="rofi -theme $theme_path"
notes_file_path="/home/$USER/.apuntes.block"

## Menu options
type_categorie=" Alta\n Media\n Baja"
principal_menu=" Nueva Nota\n Consulta\n Borrar nota"
type_input_form=""

if [[ ! -f $notes_file_path ]];
then
	touch $notes_file_pat
fi

# Note categorie
show_input_form() {
	rofi -dmenu\
		-i\
		-no-fixed-num-lines\
		-p "$type_input_form"
}

if [[ $1 == "-n" ]];
then
	selected_option=$(echo -e "$principal_menu" | $rofi_command -dmenu -selected_row 0)
	date_note=$(date +'%d/%m/%Y %H:%M')
	count_notes=$(echo "$(cat $notes_file_path | wc -l) + 1" | bc -l)

	if [[ $selected_option == " Nueva Nota" ]];
	then
		validate="True"
		categorie_select=$(echo -e "$type_categorie" | $rofi_command -dmenu -selected_row 0)

		categorie_select=$(echo -e "$categorie_select" | cut -d " " -f 2)
		type_input_form="Descripción"
		description=$(show_input_form &)
		if [[ $description == "" ]];
		then
			validate="False"	
		fi

		type_input_form="Alarma (d/m/y H:M)"
		alert_date=$(show_input_form &)
		if [[ $alert_date == "" ]];
		then
			validate="False"	
		fi

		if [[ $validate == "True" ]];
		then
			final_note_format="$count_notes|$date_note|$description|$categorie_select|$alert_date"
			result=$(echo -e $final_note_format >> $notes_file_path)
		fi
	  cat "$notes_file_path" | cut -d "|" -f 2,3 | sed "s/|/  /g" | $rofi_command -dmenu -selected_row 0
	fi

	if [[ $selected_option == " Consulta" ]];
	then
		type_input_form=$selected_option
		query_data=$(show_input_form &)

		query_result=$(cat "$notes_file_path" | grep "$query_data" | cut -d "|" -f 2,3 | sed "s/|/  /g")
		echo -e "$query_result" | $rofi_command -dmenu -selected_row 0
	fi

	if [[ $selected_option == " Borrar nota" ]];
	then
		type_input_form=$selected_option
		delete_ref=$(cat "$notes_file_path" | cut -d "|" -f 1,2,3 | sed "s/|/  /g" | $rofi_command -dmenu -selected_row 0)
		if [[ $delete_ref != "" ]];
		then
			result=$(sed -i "/$(echo "$delete_ref" | cut -d " " -f 1)|/d" $notes_file_path)
		fi
		cat "$notes_file_path" | cut -d "|" -f 1,2,3 | sed "s/|/  /g" | $rofi_command -dmenu -selected_row 0
	fi
fi

### Parámetro -r para la ejecución en segundo plano en polybar, crontab...
### Envía notificaciones al sistema y saca un string con el recuento de tareas por tipo.
if [[ $1 == "-r" ]];
then
	date_note=$(date +'%d-%m-%Y %H:%M')
	
	exec_notes=$(cat "$notes_file_path" | grep "$date_note" | cut -d "|" -f 3)
	if [[ $exec_notes != "" ]];
	then
		notify-send  "TakeNotesRofi" "$exec_notes"
	fi	
  ## Contador de tareas por prioridad.	
	low_priority=$(cat $notes_file_path | grep "Baja" | wc -l)
	medium_priority=$(cat $notes_file_path | grep "Media" | wc -l)
	high_priority=$(cat $notes_file_path | grep "Alta" | wc -l)

	echo -e " $high_priority  $medium_priority  $low_priority"
fi
