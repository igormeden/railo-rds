<!---
	Author: Anthony Cole
	Email: acole76<at>gmail.com
	
	Credit :
		Paul Klinkenberg

	Version : 1.0.2
--->
<cfsetting showdebugoutput="false" enablecfoutputonly="true"/>
<cfparam name="action" default="IDE_DEFAULT"/>

<cfset debug = structnew()/>
<cfset debug.enabled = false/>
<cfset debug.path = "/opt/railo/tomcat/webapps/ROOT/cfide/main"/>

<cfset req = GetHttpRequestData()/>
<cfset rds_command = req.content />

<cffunction name="logger" access="private" output="false" returntype="void">
	<cfargument name="logtype" type="string" required="true"/> 
	<cfargument name="str" type="string" required="true"/> 
	
	<cftry>
		<cffile action="append" file="#debug.path#\rds.txt" output="[#dateformat(now(), "yyyy-mm-dd")# #timeformat(now(), "HH:mm:ss")#][#logtype#]	#str#"/>
		
		<cfcatch type="any"></cfcatch>
	</cftry>
</cffunction>

<cffunction name="getCommandData" returntype="array" output="false">
	<cfargument name="rawdata" required="true" type="string"/>
	
	<!--- This function was derived from work by Paul Klinkenberg --->

	<cfset rawdata = listrest(arguments.rawdata, ":")/>
	<cfset spos = findnocase("str:", arguments.rawdata)/>

	<cfset return_array = arraynew(1)/>
	<cfloop condition="#spos#">
		<cfset length = listfirst(mid(arguments.rawdata, spos+4, len(arguments.rawdata)), ":")/>
		<cfset arrayappend(return_array, mid(arguments.rawdata, spos+4+len(length)+1, length))/>
		<cfset spos = findnocase("str:", arguments.rawdata, spos+length+1)/>
	</cfloop>
	
	<cfreturn return_array/>
</cffunction>

<cfif debug.enabled>
	<cfset logger("query", cgi.query_string)/>
	<cfset logger("request", rds_command)/>
</cfif>

<cfif structkeyexists(url, "rds_command") and debug.enabled>
	<cfset loop_array = getCommandData(url.rds_command)/>
<cfelse>
	<cfset loop_array = getCommandData(rds_command)/>
</cfif>

<cfobject name="RDSObject" component="rds"/>

<cfswitch expression="#lcase(action)#">
	<cfcase value="browsedir_studio,browsedir">
		<cfset output = RDSObject.browsedir_studio(loop_array)/>
	</cfcase>
	<cfcase value="dbfuncs">
		<cfswitch expression="#lcase(loop_array[2])#">
			<cfcase value="dsninfo">
				<cfset output = RDSObject.dsninfo(loop_array)/>
			</cfcase>
			<cfcase value="tableinfo">
				<cfset output = RDSObject.tableinfo(loop_array)/>
			</cfcase>
			<cfcase value="columninfo">
				<cfset output = RDSObject.columninfo(loop_array)/>
			</cfcase>
			<cfcase value="sqlstmnt">
				<cfset output = RDSObject.sqlstmnt(loop_array)/>
			</cfcase>			
			<cfdefaultcase></cfdefaultcase>
		</cfswitch>
	</cfcase>
	<cfcase value="FileIO">
		<cfswitch expression="#lcase(loop_array[2])#">
			<cfcase value="read">
				<cfset output = RDSObject.read_file(loop_array)/>
			</cfcase>
			<cfcase value="write">
				<cfset output = RDSObject.write_file(loop_array)/>
			</cfcase>
			<cfcase value="rename">
				<cfset output = RDSObject.rename_file(loop_array)/>
			</cfcase>
			<cfcase value="remove">
				<cfset output = RDSObject.remove(loop_array)/>
			</cfcase>
			<cfcase value="existence">
				<cfset output = RDSObject.exists_file(loop_array)/>
			</cfcase>
			<cfcase value="create">
				<cfset output = RDSObject.create_folder(loop_array)/>
			</cfcase>
			<cfdefaultcase>
				<cfset output = "4:4:-50037:ColdFusion Server Version: 7, 0, 0, 037:ColdFusion Client Version: 7, 0, 0, 01:1"/>
			</cfdefaultcase>
		</cfswitch>
	</cfcase>
	<cfdefaultcase>
		<cfset output = "4:4:-50037:ColdFusion Server Version: 7, 0, 0, 037:ColdFusion Client Version: 7, 0, 0, 01:1"/>
	</cfdefaultcase>
</cfswitch>

<cfif debug.enabled>
	<cfset logger("response", output)/>
</cfif>

<cfif structkeyexists(url, "rds_command") and debug.enabled>
	<cfcontent reset="false" />
<cfelse>
	<cfcontent reset="true" />
</cfif>

<cfprocessingdirective suppresswhitespace="false"><cfoutput>#output#</cfoutput></cfprocessingdirective>