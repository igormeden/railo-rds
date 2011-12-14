<!---
	Author: Anthony Cole
	Email: acole76<at>gmail.com
	
	Credit :
		Paul Klinkenberg

	Version : 1.0.1
--->
<cfsetting showdebugoutput="false" enablecfoutputonly="true"/>
<cfparam name="action" default="IDE_DEFAULT"/>

<cfset debug = structnew()/>
<cfset debug.enabled = true/>
<cfset debug.path = expandpath("/")/>

<cfset req = GetHttpRequestData()/>
<cfset rds_command = req.content />

<cffunction name="getCommandData" returntype="array" output="false">
	<cfargument name="rawdata" required="true" type="string"/>
	
	<!--- This function was derived from work by Paul Klinkenberg --->
	<!--- Thank you Paul for all your help --->
	
	<cfset req = GetHttpRequestData()/>
	<cfset loop_data = arraynew(1)/>
	
	<cfset nDataLen = len(arguments.rawdata) />
	<cfset nIndex = 1 />
	<cfloop condition="nIndex lte nDataLen">
		<cfif nIndex eq 1>
			<cfset variables.loop_data[1] = listFirst(arguments.rawdata, ':') />
			<cfset nIndex = len(variables.loop_data[1]) + 2 />
		<cfelseif refind('STR:[0-9]+:', arguments.rawdata, nIndex) eq nIndex>
			<cfset nStrLen = listFirst(mid(arguments.rawdata, nIndex + 4, nDataLen), ':') />
			<cfset arrayAppend(variables.loop_data, mid(arguments.rawdata, nIndex + 4 + len(nStrLen) + 1, nStrLen)) />
			<cfset nIndex = nIndex + 4 + len(nStrLen) + 1 + nStrLen />
		<cfelseif mid(arguments.rawdata, nIndex, 1) eq ','>
			<!--- end of this form key; we're done --->
			<cfset nIndex = len(arguments.rawdata)+1 />
		<cfelse>
			<cfthrow message="Unknown data starting from character #nIndex# in string #arguments.rawdata#" />
		</cfif>
	</cfloop>
	
	<!--- the rest of my code doesn't need the first element of the array --->
	<cfset return_array = arraynew(1)/>	
	<cfloop from="2" to="#arraylen(variables.loop_data)#" index="i">
		<cfset arrayappend(return_array, variables.loop_data[i])/>
	</cfloop>
	
	<cfreturn return_array/>
</cffunction>

<cfif debug.enabled>
	<cffile action="append" file="#debug.path#\rds.txt" output="[query]	#cgi.query_string#"/>
	<cffile action="append" file="#debug.path#\rds.txt" output="[request]	#rds_command#"/>
</cfif>
 
<cfset loop_array = getCommandData(rds_command)/>

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
	<cffile action="append" file="#debug.path#\rds.txt" output="[response]	#output#"/>
</cfif><cfcontent reset="true" /><cfprocessingdirective suppresswhitespace="false"><cfoutput>#output#</cfoutput></cfprocessingdirective>
