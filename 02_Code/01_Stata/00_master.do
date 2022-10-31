clear
set more off

local user "Marco"

global muestra = "muestra_1porciento"

global star "star(* 0.1 ** 0.05 *** 0.01)"
	
if "`user'" == "Marco" {
	global directory "/Users/marcomedina/ITAM Seira Research Dropbox/Marco Alejandro Medina/imss_rpci"
	cd "$directory"
	}

if "`user'" == "Marco Desktop" {
	global directory "C:/Users/Guest/ITAM Seira Research Dropbox/Marco Alejandro Medina/imss_rpci"
	cd "$directory"
}

if "`user'" == "Marco Remote" {
	global directory "E:\DATA\IMSS"
	cd "$directory"
}
