HA$PBExportHeader$facturacion.sra
$PBExportComments$Facturacion de comisiones
forward
global type facturacion from application
end type
global transaction sqlca
global dynamicdescriptionarea sqlda
global dynamicstagingarea sqlsa
global error error
global message message
end forward

global variables
 DECLARE h PROCEDURE FOR sp_consulta_aplicacion_pago  
         @num_pago = 3  ;

//*** variable de seguridad
int gi_tipo_open
string is_usuario, is_clave
e_usuario e_usuario
int gi_cod_modulo = 4 // NO BORRAR CODIGO DE MODULO DE SEGURIDAD

double gdb_negocio, gdb_nro_factura, gd_saldo_factura
string gs_cuenta
date gd_fecha_factura
string gs_proceso
string gs_version
end variables

global type facturacion from application
string appname = "facturacion"
end type
global facturacion facturacion

type variables
boolean ib_barra_pruebas // SE usa esta mientras se puede colocar la global
end variables

on facturacion.create
appname="facturacion"
message=create message
sqlca=create transaction
sqlda=create dynamicdescriptionarea
sqlsa=create dynamicstagingarea
error=create error
end on

on facturacion.destroy
destroy(sqlca)
destroy(sqlda)
destroy(sqlsa)
destroy(error)
destroy(message)
end on

event open;string puntoini
string  ls_nombre_pc, ls_barra_pruebas, ls_servername, ls_database

ib_barra_pruebas = FALSE

//++++
// adicion de LA RECEPCION DE PARAMETROS DE EJECUTABLES
// Valida que la aplicaci$$HEX1$$f300$$ENDHEX$$n no se encuentre en ejecuci$$HEX1$$f300$$ENDHEX$$n ya.
// Ojo: el t$$HEX1$$ed00$$ENDHEX$$tulo de la ventana principal de la aplicaci$$HEX1$$f300$$ENDHEX$$n no debe variar. ls_titulo se hace igual al t$$HEX1$$ed00$$ENDHEX$$tulo 
string ls_titulo
uint  val
ls_titulo = "DIALOGO ADMINISTRACION DEL SISTEMA"
gs_version = '[Vers: 2.0.1.63]'
//val = FindWindowA(0, ls_titulo)
//IF val > 0 THEN
//	MessageBox("Validacion","La aplicacion ya esta en ejecuci$$HEX1$$f300$$ENDHEX$$n~r~n" )
//	HALT CLOSE
//end if

// Realiza la conexi$$HEX1$$f300$$ENDHEX$$n a la base de datos y valida al usuario que ingresa
// La variable global gb_entrada ayuda a controlar a que base entrar : True - base de Sql Server. False - base de datos local
string ls_clave, ls_pasan, ls_usuario, ls_dbms
datetime ldt_hoy
integer li_pos, li_aplicacion

// Lectura de los par$$HEX1$$e100$$ENDHEX$$metros de ejecuci$$HEX1$$f300$$ENDHEX$$n
string ls_cmd, ls_arg[]
integer li_argcnt, i, li_empresa
ls_cmd = Trim(CommandParm())
li_argcnt = 1
//ls_cmd = "U1026288743 F9ADEF263D6C4A728BA74D022B7A0676853DAFBEE4D757C6BD168d32adc216323f76ac4e19fb2696d0f9f1d7f6c1e19e4c18421411a5d7858bc74c7ce3dd77ae 1"//"U1026288743 F9ADEF263D6C4A728BA74D022B7A0676853DAFBEE4D757C6BD168d32adc216323f76ac4e19fb2696d0f9f1d7f6c1e19e4c18421411a5d7858bc74c7ce3dd77ae 1"//
Ls_cmd = "U79762003 1499CF620D0CA3984C5DBF32C5A1978B7EBBAC33DF7AE33C8A634e5accef1181cf0706f2519f05f328397c5b0c549a6cf8b8ce61d68bf39bf792e74f3f982c0c 1"
Ls_cmd = "U1094903043 1499CF620D0CA3984C5DBF32C5A1978B7EBBAC33DF7AE33C8A634e5accef1181cf0706f2519f05f328397c5b0c549a6cf8b8ce61d68bf39bf792e74f3f982c0c 1"

//
DO WHILE Len(ls_cmd) > 0 
	i = Pos(ls_cmd, " ")
	if i=0 then i = Len(ls_cmd) + 1
	ls_arg[li_argcnt] = Left(ls_cmd, i - 1)
	li_argcnt = li_argcnt + 1
	ls_cmd = Replace(ls_cmd, 1, i, " ")
	ls_cmd = trim(ls_cmd)
LOOP

if upperbound(ls_arg) > 0 then
	ls_usuario = trim(ls_arg[1])
	ls_clave = trim(ls_arg[2])
	li_aplicacion = Integer(trim(ls_arg[3]))
	If upperbound(ls_arg) = 6 Then
		ls_barra_pruebas	= trim(ls_arg[4])
		ls_servername		= trim(ls_arg[5])
		ls_database			= trim(ls_arg[6])
	End If
end if

//If ls_barra_pruebas = 'BARRA_PRUEBAS' Then	ib_barra_pruebas = TRUE

//ls_usuario = 'sa'
//ls_clave   = 'tecno' // PRODUCCION
//
//ls_usuario = 'U79952000'
//ls_clave   = 'D1$$HEX7$$aa00b000aa00af00b600b000b200$$ENDHEX$$wz' // PRODUCCION

//ls_usuario = 'dlopez'
//ls_clave   = 'Dialogo01' // PRODUCCION

//ls_usuario = 'U1026288743'
//ls_clave   = 'D1$$HEX7$$aa00b000aa00af00b600b000b200$$ENDHEX$$wz' // PRODUCCION



puntoini = "c:\dgcontab\dlgcon02.ini"
//puntoini = "..\dialogo.ini"

if not FileExists(puntoini) then  
	messageBox("Mensaje Informativo", "Falta un elemento en el programa ..\dialogo.ini.~nEl programa no ha sido correctamente instalado,~n por favor llamar al ing. Encargado")
	halt close
end if

// Entrada a la base de datos del servidor de base de datos
string ls_dbparm
// Verifica la existencia del archivo de Configuraci$$HEX1$$f300$$ENDHEX$$n de la Conexi$$HEX1$$f300$$ENDHEX$$n 'c:\dgcontab\dlgcon02.ini"
ldt_hoy = datetime(fg_fechahora())

sqlca.DBMS        	= ProfileString(puntoini,"sqlca","dbms","")
If Not ib_barra_pruebas Then
//	sqlca.dbms       		= (trim(ProfileString(puntoini,"sqlca","DBMS","")))
//	sqlca.database   		= (trim(ProfileString(puntoini,"sqlca","DATABASE_DIALOGO","")))
//	sqlca.servername 		= (trim(ProfileString(puntoini,"sqlca","SERVERNAME","")))
//	sqlca.dbparm	  		= lower(trim(ProfileString(puntoini,"sqlca","DBPARM_DIALOGO","")))
	
	sqlca.dbms       		= (trim(ProfileString(puntoini,"sqlca","DBMS121","")))
	sqlca.database   		= (trim(ProfileString(puntoini,"sqlca","Database","")))
	sqlca.servername 		= (trim(ProfileString(puntoini,"sqlca","SERVERNAME","")))
	sqlca.dbparm	  		= lower(trim(ProfileString(puntoini,"sqlca","dbparm121","")))
	sqlca.lock = "RC"

	sqlca.dbparm = sqlca.dbparm + ",PBTrimCharColumns='Yes',TrimSpaces=1"
Else // El aplicativo se est$$HEX2$$e1002000$$ENDHEX$$ejecutando desde la barra de pruebas: LA BARRA pasa como argumento bd y servername
	sqlca.database    = ls_database
	sqlca.servername = ls_servername
	MessageBox('ATENCION','El aplicativo Cart Comis PB65 se est$$HEX2$$e1002000$$ENDHEX$$ejecutando desde la barra de pruebas', Exclamation!)
End If
//sqlca.dbparm	    	= ProfileString(puntoini,"sqlca","dbparm","")
sqlca.userid			= trim(ls_usuario)
sqlca.dbpass		= trim(ls_clave)
sqlca.logid			= trim(ls_usuario)
sqlca.logpass		= trim(ls_clave)

//ls_usuario = 'U20983452'	// CAMBIO BD

// Inicializa la variable global de usuario quitando los espacios 
e_usuario.usuario_base	= trim(ls_usuario)
ls_clave = trim(ls_clave)

// Establece el autocommit seg$$HEX1$$fa00$$ENDHEX$$n DBMS
ls_dbms = mid(upper(sqlca.dbms),1,3)
ls_dbms = trim(ls_dbms)
if ls_dbms <> "SYC" and ls_dbms <> "SYB" and ls_dbms <> "MSS" and ls_dbms <> "ODB"  THEN
	li_pos = Pos("ORA",upper(sqlca.dbms))
	if li_pos > 0 then ls_dbms = "ORA"
end if


CHOOSE CASE  ls_dbms
	 CASE  "SYB"  ;  sqlca.autocommit = true
	 CASE  "ODB"  ;  sqlca.autocommit = true
	 CASE  "SYC"  ;  sqlca.autocommit = true
	 CASE  "MSS"  ;  sqlca.autocommit = true
	 CASE  "ORA"  ;  sqlca.autocommit = true
	 CASE ELSE ;  sqlca.autocommit = true 
END CHOOSE 
CONNECT USING SQLCA;

if sqlca.sqlcode <> 0 then
	MessageBox("Mensaje Informativo","No es posible establecer conexi$$HEX1$$f300$$ENDHEX$$n con la base de datos.~r~n"&
	+'Srv: '+sqlca.servername+'-BD: '+sqlca.database+'-Usr: '+sqlca.userid+'-'+ string(sqlca.SQLErrText), information!)
	return
end if

SELECT dv11usr1.dv11_empresa,
		dv11usr1.cod_usuario
	INTO :e_usuario.empresa ,
		:e_usuario.usuario
FROM dv11usr1  
WHERE dv11usr1.usuario_base = :ls_usuario;


// Consulta y fija la informaci$$HEX1$$f300$$ENDHEX$$n del usuario que ingres$$HEX1$$f300$$ENDHEX$$
if fg_describe_usr(e_usuario.usuario_base) then
	// LLeva al idle el tiempo de espera asignado al usuario
	idle(e_usuario.tiempo_espera)	
else
	MessageBox ("Mensaje Informativo","No hay descripci$$HEX1$$f300$$ENDHEX$$n del usuario que ingresa",information!)
	halt close
	Return
end if


//++++
open (w_login)
open (w_principal)
end event

