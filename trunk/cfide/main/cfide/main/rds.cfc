<!---
	Author: Anthony Cole
	Email: acole76<at>gmail.com
	
	Credit :
		Paul Klinkenberg

	Version : 1.0.1
--->
<cfcomponent>
	<cfset login_error_msg = "-100:Unable to authenticate on RDS server using current security information !"/>
	<cffunction name="decryt_rds" output="false" returntype="string" access="public">
		<cfargument name="password" required="true" type="string"/>
		
		<cfset key = "4p0L@r1$"/>
		<cfset return_string = ""/>
		<cfset keyi = 1/>
		<cfloop from="1" to="#len(arguments.password)#" index="i" step="2">
			<cfset kletter = asc(mid(key, keyi, 1))/>
			<cfset pletter = inputbasen(mid(arguments.password, i, 2), 16)/>
			<cfset return_string = return_string & chr(bitxor(pletter, kletter))/>
	
			<cfset keyi = keyi + 1/>
			<cfif keyi gt len(key)>
				<cfset keyi = 1/>
			</cfif>
		</cfloop>
		
		<cfreturn return_string/>
	</cffunction>

	<cffunction name="authenticateUser" access="private" output="false" returntype="boolean">
		<cfargument name="authstring" required="true" default="" type="string"/>
		
		<cfset var username = ""/>
		<cfset var password = decryt_rds(listlast(arguments.authstring, ";"))/>
		<cfif mid(arguments.authstring, 1, 1) neq ";">
			<cfset var username = listfirst(arguments.authstring, ";")/>
		</cfif>		
		
		<cfset qUsers = querynew("username,password")/>
		<cfset queryaddrow(qUsers)/>
		<cfset querysetcell(qUsers, "username", "")/>
		<cfset querysetcell(qUsers, "password", "password")/>
		
		<cfquery name="qLogin" dbtype="query">
			select * from qUsers
			where 	username = <cfqueryparam cfsqltype="cf_sql_varchar" value="#username#"/> and
					password = <cfqueryparam cfsqltype="cf_sql_varchar" value="#password#"/>
		</cfquery>
		
		<cfif qLogin.recordcount>
			<cfreturn true/>
		<cfelse>
			<cfreturn false/>
		</cfif>
	</cffunction>
	
	<cffunction name="browsedir_studio" returntype="string" access="public" output="false">
		<cfargument name="args" type="array" default="#arraynew(1)#" required="true"/>
		
		<cfif authenticateUser(args[arraylen(arguments.args)]) eq false>
			<cfreturn login_error_msg/>
		</cfif>
		
		<cftry>
			<cfset str = ""/>
			<cfif len(args[1])>
				<cfdirectory directory="#args[1]#" name="qDir"/>
				
				<cfset str = str & "#qDir.recordcount*5#:"/>
				
				<cfoutput query="qDir">
					<cfif listfind(".,..", qDir.name) eq 0>
						<cfset str = str & "2:"/>
						<cfif lcase(qDir.type) eq "file">
							<cfset str = str & "F:"/>
							<cfset size = qDir.size/>
						<cfelse>
							<cfset str = str & "D:"/>
							<cfset size = 0/>
						</cfif>
						
						<cfset last_modified = "#int(qDir.dateLastModified.getTime()/1000)#,#int(qDir.dateLastModified.getTime()/1000)#"/>
						<cfset str = str & "#len(qDir.name)#:"/>
						<cfset str = str & "#qDir.name#"/>
						<cfset str = str & "1:6#len(size)#:#size##len(last_modified)#:#last_modified#"/>
					</cfif>
				</cfoutput>
			<cfelse>
				<cfset FileObject = createobject("java", "java.io.File")/>
				<cfset roots = FileObject.listRoots()/>
				
				<cfloop from="1" to="#arraylen(roots)#" index="i">
					<cfset str = str & "1:33:#roots[i].getPath()#0:"/>
				</cfloop>
				
				<cfset str = "#arraylen(roots)*3#:#str#"/>
			</cfif>
			
			<cfreturn str/>
			
			<cfcatch type="Any">
				<cfreturn "-1:[browsedir_studio] #cfcatch.message#. #cfcatch.detail#"/>
			</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="read_file" returntype="string" access="public" output="false">
		<cfargument name="args" type="array" default="#arraynew(1)#" required="true"/>
		
		<cfif authenticateUser(args[arraylen(arguments.args)]) eq false>
			<cfreturn login_error_msg/>
		</cfif>

		<cftry>
			<cfif fileexists(args[1])>
				<cfdirectory directory="#getdirectoryfrompath(args[1])#" name="qDir" filter="#getfilefrompath(args[1])#"/>
				<cffile action="read" file="#args[1]#" variable="read_var"/>
				<cfset str = "#len(len(read_var))#:"/>
				<cfset str = str & "#len(read_var)#:"/>
				<cfset str = str & "#read_var#"/>
				<cfset now_date = "#timeformat(qDir.dateLastModified, "hh:mm:ssTT")#   #dateformat(qDir.dateLastModified, "mm/dd/yyyy")#"/>
				<cfset str = str & "#len(now_date)#:"/>
				<cfset str = str & "#now_date#6:Normal"/>
			<cfelse>
				<cfreturn "-1:file not found"/>
			</cfif>
			
			<cfreturn str/>
			
			<cfcatch type="Any">
				<cfreturn "-1:[read_file] #cfcatch.message#. #cfcatch.detail#"/>
			</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="write_file" returntype="string" access="public" output="false">
		<cfargument name="args" type="array" default="#arraynew(1)#" required="true"/>
		
		<cfif authenticateUser(args[arraylen(arguments.args)]) eq false>
			<cfreturn login_error_msg/>
		</cfif>
		
		<cftry>
			<cffile action="write" file="#args[1]#" output="#args[4]#"/>
			<cfreturn "1:2:XX"/>
			
			<cfcatch type="Any">
				<cfreturn "-1:[write_file] #cfcatch.message#. #cfcatch.detail#"/>
			</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="rename_file" returntype="string" access="public" output="false">
		<cfargument name="args" type="array" default="#arraynew(1)#" required="true"/>
		
		<cfif authenticateUser(args[arraylen(arguments.args)]) eq false>
			<cfreturn login_error_msg/>
		</cfif>
		
		<cftry>
			<cfif fileexists(args[1])>
				<cffile action="rename" source="#args[1]#" destination="#args[4]#"/>
				<cfreturn "1:0:"/>
			<cfelse>
				<cfif directoryexists(args[1])>
					<cfdirectory action="rename" directory="#args[1]#" newdirectory="#args[4]#"/>
					<cfreturn "1:0:"/>
				<cfelse>
					<cfreturn "-1:[rename_file] file not found"/>
				</cfif>
			</cfif>
			
			<cfcatch type="Any">
				<cfreturn "-1:[rename_file] #cfcatch.message#. #cfcatch.detail#"/>
			</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="remove" returntype="string" access="public" output="false">
		<cfargument name="args" type="array" default="#arraynew(1)#" required="true"/>
		
		<cfif authenticateUser(args[arraylen(arguments.args)]) eq false>
			<cfreturn login_error_msg/>
		</cfif>

		<cftry>
			<cfif lcase(args[4]) eq "d">
				<cfif directoryexists(args[1])>
					<cfdirectory action="delete" directory="#args[1]#"/>
					<cfreturn "1:0:"/>
				<cfelse>
					<cfreturn "-1:[remove_file] directory not found"/>
				</cfif>
			<cfelse>
				<cfif fileexists(args[1])>
					<cffile action="delete" file="#args[1]#"/>
					<cfreturn "1:0:"/>
				<cfelse>
					<cfreturn "-1:[remove_file] file not found"/>
				</cfif>
			</cfif>
			
			<cfcatch type="Any">
				<cfreturn "-1:[remove_file] #cfcatch.message#. #cfcatch.detail#"/>
			</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="exists_file" returntype="string" access="public" output="false">
		<cfargument name="args" type="array" default="#arraynew(1)#" required="true"/>
		
		<cfif authenticateUser(args[arraylen(arguments.args)]) eq false>
			<cfreturn login_error_msg/>
		</cfif>
		
		<cftry>
			<cfif fileexists(args[1])>
				<cfreturn "1:0:"/>
			<cfelse>
				<cfreturn "-1:file not found"/>
			</cfif>
			
			<cfcatch type="Any">
				<cfreturn "-1:[exists_file] #cfcatch.message#. #cfcatch.detail#"/>
			</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="create_folder" returntype="string" access="public" output="false">
		<cfargument name="args" type="array" default="#arraynew(1)#" required="true"/>
		
		<cfif authenticateUser(args[arraylen(arguments.args)]) eq false>
			<cfreturn login_error_msg/>
		</cfif>
		
		<cftry>
			<cfdirectory action="create" directory="#args[1]#"/>
		
			<cfreturn "1:0:"/>
			
			<cfcatch type="Any">
				<cfreturn "-1:[create_folder] #cfcatch.message#. #cfcatch.detail#"/>
			</cfcatch>
		</cftry>
	</cffunction>
	
	
	<!--- DBFUNCS --->
	<cffunction name="dsninfo" returntype="string" access="public" output="false">
		<cfargument name="args" type="array" default="#arraynew(1)#" required="true"/>
		
		<cfif authenticateUser(args[arraylen(arguments.args)]) eq false>
			<cfreturn login_error_msg/>
		</cfif>

		<cftry>
			<cfadmin action="getDatasources" type="web" returnVariable="qDataSrc"/>
			
			<cfset str = "#qDataSrc.recordcount#:"/>
			<cfoutput query="qDataSrc">
				<cfset name = qDataSrc.name/>
				<cfset line = '"#name#","","SYSTEM"'/>
				<cfset str = str & "#len(line)#:#line#"/>
			</cfoutput>
			
			<cfreturn str/>
			
			<cfcatch type="Any">
				<cfreturn "-1:#cfcatch.message#.  #cfcatch.detail#"/>
			</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="tableinfo" returntype="string" access="public" output="false">
		<cfargument name="args" type="array" default="#arraynew(1)#" required="true"/>
		
		<cfif authenticateUser(args[arraylen(arguments.args)]) eq false>
			<cfreturn login_error_msg/>
		</cfif>

		<cfset params = listtoarray(args[1], ";")/>
		
		<cftry>
			<cfadmin action="getDatasources" type="web" returnVariable="qDataSrc"/>
			
			<cfquery name="qDatasrc" dbtype="query">
				select * from qDataSrc
				where name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#params[1]#"/>
			</cfquery>
			
			<cfset dm = createobject("java", "java.sql.DriverManager")/>
			<cfset conn = dm.getConnection(qDataSrc.DsnTranslated, qDataSrc.username, qDataSrc.password)/>
			<cfset schema_object = conn.getMetaData().getTables(javaCast("null", ""), javaCast("null", ""), "%", javaCast("null", ""))/>
			
			<cfset qTables = querynew("table_cat,table_schem,table_name,table_type,remarks")/>
			<cfloop condition="#schema_object.next()#">
				<cfset queryaddrow(qTables)/>
				<cfset querysetcell(qTables, "table_cat", schema_object.getString("table_cat"))/>
				<cfset querysetcell(qTables, "table_schem", schema_object.getString("table_schem"))/>
				<cfset querysetcell(qTables, "table_name", schema_object.getString("table_name"))/>
				<cfset querysetcell(qTables, "table_type", schema_object.getString("table_type"))/>
				<cfset querysetcell(qTables, "remarks", schema_object.getString("remarks"))/>
			</cfloop>
			
			<cfset str = "#qTables.recordcount#:"/>
			<cfoutput query="qTables">
				<cfset line = '"#qTables.table_cat#","#qTables.table_schem#","#qTables.table_name#","#qTables.table_type#"'/>
				<cfset str = str & "#len(line)#:#line#"/>
			</cfoutput>
			
			<cfreturn str/>
			
			<cfcatch type="Any">
				<cfreturn "-1:#cfcatch.message#.  #cfcatch.detail#"/>
			</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="columninfo" returntype="string" access="public" output="false">
		<cfargument name="args" type="array" default="#arraynew(1)#" required="true"/>
		
		<cfif authenticateUser(args[arraylen(arguments.args)]) eq false>
			<cfreturn login_error_msg/>
		</cfif>

		<cfset params = listtoarray(args[1], ";")/>
		
		<cftry>
			<cfadmin action="getDatasources" type="web" returnVariable="qDataSrc"/>
			
			<cfquery name="qDatasrc" dbtype="query">
				select * from qDataSrc
				where name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#params[1]#"/>
			</cfquery>
			
			<cfset dm = createobject("java", "java.sql.DriverManager")/>
			<cfset conn = dm.getConnection(qDataSrc.DsnTranslated, qDataSrc.username, qDataSrc.password)/>
			<cfset table_name = listlast(args[3], ".")/>
			<cfset schema_object = conn.getMetaData().getColumns(javaCast("null", ""), javaCast("null", ""), table_name, javaCast("null", ""))/>

			<cfset qColumns = querynew("table_cat,table_schem,table_name,column_name,data_type,type_name,column_size,is_nullable,table_type,remarks")/>
			<cfloop condition="#schema_object.next()#">
				<cfset queryaddrow(qColumns)/>
				<cfset querysetcell(qColumns, "table_cat", schema_object.getString("table_cat"))/>
				<cfset querysetcell(qColumns, "table_schem", schema_object.getString("table_schem"))/>
				<cfset querysetcell(qColumns, "table_name", schema_object.getString("table_name"))/>
				<cfset querysetcell(qColumns, "column_name", schema_object.getString("column_name"))/>
				<cfset querysetcell(qColumns, "data_type", schema_object.getString("data_type"))/>
				<cfset querysetcell(qColumns, "type_name", schema_object.getString("type_name"))/>
				<cfset querysetcell(qColumns, "column_size", schema_object.getString("column_size"))/>
			</cfloop>

			<cfset str = "#qColumns.recordcount#:"/>
			<cfoutput query="qColumns">
				<cfset line = '"#qDatasrc.database#","","#table_name#","#qColumns.column_name#","#qColumns.data_type#","#qColumns.type_name#","0","0","0","0","0"'/>
				<cfset str = str & "#len(line)#:#line#"/>
			</cfoutput>
			
			<cfreturn str/>
			
			<cfcatch type="Any">
				<cfreturn "-1:#cfcatch.message#.  #cfcatch.detail#"/>
			</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="sqlstmnt" returntype="string" access="public" output="false">
		<cfargument name="args" type="array" default="#arraynew(1)#" required="true"/>
		
		<cfif authenticateUser(args[arraylen(arguments.args)]) eq false>
			<cfreturn login_error_msg/>
		</cfif>

		<cfset params = listtoarray(args[1], ";")/>

		<cftry>
			<cfquery name="qQuery" datasource="#params[1]#">
				#preservesinglequotes(args[3])#
			</cfquery>

			<cfset column_array = listtoarray(qQuery.columnlist)/>
			
			<cfset str = "#qQuery.recordcount#:"/>
			<cfset headers = ""/>
			<cfloop from="1" to="#arraylen(column_array)#" index="i">
				<cfset headers = listappend(headers, '"#column_array[i]#"')/>
			</cfloop>
			
			<cfset str = str & "#len(headers)+1#:#lcase(headers)#,"/>
			<cfoutput query="qQuery">
				<cfset line = ""/>
				<cfloop from="1" to="#arraylen(column_array)#" index="i">
					<cfset line = listappend(line, '"#qQuery[column_array[i]][qQuery.currentrow]#"')/>
				</cfloop>
				<cfset str = str & "#len(line)+1#:#line#,"/>
			</cfoutput>
			
			<cfreturn str/>
			
			<cfcatch type="Any">
				<cfreturn "-1:#cfcatch.message#.  #cfcatch.detail#"/>
			</cfcatch>
		</cftry>
	</cffunction>
</cfcomponent>
