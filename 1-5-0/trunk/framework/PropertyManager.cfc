<!---
License:
Copyright 2006 Mach-II Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Copyright: Mach-II Corporation
$Id$

Created version: 1.0.0
Updated version: 1.5.0

Notes:
- Deprecated hasProperty(). Duplicate method isPropertyDefined is more inline with
the rest of the framework. (pfarrell)
- Added method to get Mach-II framework version (pfarrell)
--->
<cfcomponent 
	displayname="PropertyManager"
	output="false"
	hint="Manages defined properties for the framework.">
	
	<!---
	PROPERTIES
	--->
	<cfset variables.appManager = "" />
	<cfset variables.properties = StructNew() />
	<cfset variables.version = "Unknown" />
	
	<!---
	INITIALIZATION / CONFIGURATION
	--->
	<cffunction name="init" access="public" returntype="void" output="false"
		hint="Initialization function called by the framework.">
		<cfargument name="configXML" type="string" required="true" />
		<cfargument name="appManager" type="MachII.framework.AppManager" required="true" />
		<cfargument name="version" type="string" required="true" />
		
		<cfset var xnProperties = "" />
		<cfset var type = "" />
		<cfset var value = "" />
		<cfset var i = 0 />
		
		<cfset setAppManager(arguments.appManager) />
		<cfset setVersion(arguments.version) />

		<!--- Set the properties from the XML file. --->
		<cfset xnProperties = XMLSearch(configXML, "//property") />

		<cfloop from="1" to="#ArrayLen(xnProperties)#" index="i">
			<!--- Check for the property type. Defaults to string --->
			<cfif StructKeyExists(xnProperties[i].xmlAttributes, "type")>
				<cfset type = xnProperties[i].xmlAttributes.type />
			<cfelse>
				<cfset type = "string" />
			</cfif>
			
			<!--- Setup based on data type --->
			<cfif type EQ "string">
				<cfset value = xnProperties[i].xmlAttributes.value />
			<cfelseif type EQ "struct">
				<cfset value = setupStruct(xnProperties[i].xmlChildren) />
			<cfelseif type EQ "array">
				<cfset value = setupArray(xnProperties[i].xmlChildren[1].xmlChildren) />
			<cfelse>
				<cfthrow message="Property CFC datatype is unimplemented." />
			</cfif>
			
			<!--- Set the property --->
			<cfset setProperty(xnProperties[i].xmlAttributes.name, value) />
		</cfloop>
		
		<!--- Make sure required properties are set: 
			defaultEvent, exceptionEvent, applicationRoot, eventParameter, parameterPrecedence, maxEvents. --->
		<cfif NOT isPropertyDefined("defaultEvent")>
			<cfset setProperty("defaultEvent", "defaultEvent") />
		</cfif>
		<cfif NOT isPropertyDefined("exceptionEvent")>
			<cfset setProperty("exceptionEvent", "exceptionEvent") />
		</cfif>
		<cfif NOT isPropertyDefined("applicationRoot")>
			<cfset setProperty("applicationRoot", "") />
		</cfif>
		<cfif NOT isPropertyDefined("eventParameter")>
			<cfset setProperty("eventParameter", "event") />
		</cfif>
		<cfif NOT isPropertyDefined("parameterPrecedence")>
			<cfset setProperty("parameterPrecedence", "form") />
		</cfif>
		<cfif NOT isPropertyDefined("maxEvents")>
			<cfset setProperty("maxEvents", 10) />
		</cfif>
	</cffunction>
	
	<cffunction name="configure" access="public" returntype="void" output="false"
		hint="Prepares the manager for use.">
		<!--- DO NOTHING --->
	</cffunction>
	
	<!---
	PUBLIC FUNCTIONS
	--->
	<cffunction name="getProperty" access="public" returntype="any" output="false"
		hint="Returns the property value by name. If the property is not defined, and a default value is passed, it will be returned. If the property and a default value are both not defined then an exception is thrown.">
		<cfargument name="propertyName" type="string" required="true" />
		<cfargument name="defaultValue" type="any" required="false" default="" />
		
		<cfif isPropertyDefined(arguments.propertyName)>
			<cfreturn variables.properties[arguments.propertyName] />
		<cfelseif StructKeyExists(arguments, "defaultValue")>
			<cfreturn arguments.defaultValue />
		<cfelse>
			<!--- This case is current unimplemented to retain backwards compatibility.
           Currently the framework does not throw an error when a property does
           not exist, but returns "".  However, in future release this action may not be
           retained and an error thrown. --->
			<cfthrow type="MachII.framework.PropertyNotDefined" 
				message="Property with name '#arguments.propertyName#' is not defined." />
		</cfif>
	</cffunction>	
	<cffunction name="setProperty" access="public" returntype="void" output="false"
		hint="Sets the property value by name.">
		<cfargument name="propertyName" type="string" required="true" />
		<cfargument name="propertyValue" type="any" required="true" />
		<cfset variables.properties[arguments.propertyName] = arguments.propertyValue />
	</cffunction>
	
	<cffunction name="isPropertyDefined" access="public" returntype="boolean" output="false"
		hint="Checks if property name is defined in the properties.">
		<cfargument name="propertyName" type="string" required="true" />
		<cfreturn StructKeyExists(variables.properties, arguments.propertyName) />
	</cffunction>
	<cffunction name="hasProperty" access="public" returntype="boolean" output="false"
		hint="DEPRECATED - use isPropertyDefined() instead. Checks if property name is deinfed in the propeties.">
		<cfargument name="propertyName" type="string" required="true" />
		<cfreturn StructKeyExists(variables.properties, arguments.propertyName) />
	</cffunction>

	<cffunction name="getProperties" access="public" returntype="struct" output="false"
		hint="Returns all properties.">
		<cfreturn variables.properties />
	</cffunction>
	
	<!---
	PROTECTED FUNCTIONS
	--->
	<cffunction name="setupStruct" access="private" returntype="struct" output="false"
		hint="Setups a struct.">
		<cfargument name="nodes" type="array" required="true" />
		
		<cfset var result = StructNew() />
		<cfset var value = "" />
		<cfset var child = "" />
		<cfset var i = 0 />
		
		<cfloop from="1" to="#ArrayLen(arguments.nodes)#" index="i">			
			<cfset result[arguments.nodes[i].xmlAttributes.name] = recurseByType(arguments.nodes[i]) />
		</cfloop>
		
		<cfreturn result />
	</cffunction>
	
	<cffunction name="setupArray" access="private" returntype="array" output="false"
		hint="Setups an array.">
		<cfargument name="nodes" type="array" required="true" />
		
		<cfset var result = ArrayNew(1) />
		<cfset var value = "" />
		<cfset var child = "" />
		<cfset var i = 0 />
		
		<cfloop from="1" to="#ArrayLen(arguments.nodes)#" index="i">			
			<cfset ArrayAppend(result, recurseByType(arguments.nodes[i])) />
		</cfloop>
		
		<cfreturn result />
	</cffunction>
	
	<cffunction name="recurseByType" access="private" returntype="any" output="false"
		hint="Recurses properties by type.">
		<cfargument name="node" type="any" required="true" />
		
		<cfset var value = "" />
		
		<cfif StructKeyExists(arguments.node.xmlAttributes, "value")>
			<cfset value = arguments.node.xmlAttributes.value />
		<cfelse>
			<cfset child = arguments.node.xmlChildren[1] />
			
			<cfif child.xmlName EQ "value">
				<cfset value = child.xmlText />
			<cfelseif child.xmlName EQ "struct">
				<cfset value = setupStruct(child.xmlChildren) />
			<cfelseif child.xmlName EQ "array">
				<cfset value = setupArray(child.xmlChildren) />
			</cfif>
		</cfif>
		
		<cfreturn value />
	</cffunction>
	
	<!---
	ACCESSORS
	--->
	<cffunction name="setAppManager" access="public" returntype="void" output="false">
		<cfargument name="appManager" type="MachII.framework.AppManager" required="true" />
		<cfset variables.appManager = arguments.appManager />
	</cffunction>
	<cffunction name="getAppManager" access="public" returntype="MachII.framework.AppManager" output="false">
		<cfreturn variables.appManager />
	</cffunction>
	
	<cffunction name="setVersion" access="private" returntype="void" output="false">
		<cfargument name="version" type="string" required="true" />
		<cfset variables.version = arguments.version />
	</cffunction>
	<cffunction name="getVersion" access="public" returntype="string" output="false"
		hint="Gets the version number of the framework.">
		<cfreturn variables.version />
	</cffunction>
	
</cfcomponent>