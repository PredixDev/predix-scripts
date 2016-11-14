import sys
import time
import subprocess
from subprocess import Popen
from subprocess import PIPE
import json
import os
import re
import base64, uuid, io, codecs, mimetypes
import shutil
import shlex
import xml.dom.minidom
try:
	from urllib2 import Request, urlopen
	from urllib2 import URLError, HTTPError
	from httplib import HTTPSConnection
except ImportError:
	from urllib.request import Request, urlopen
	from urllib.error import URLError, HTTPError
	from http.client import HTTPSConnection
from xml.dom.minidom import parse


def execCommand(command):
	print("Executing " + command)
	statementStatus = subprocess.call(command, shell=True)
	if statementStatus == 1 :
		print("Error executing " + command)
		sys.exit("Error executing " + command)

	return statementStatus

def deleteExistingApplication(applicationName):
	if doesItExist("cf a ", applicationName, 0) :
		deleteRequest = "cf delete -f -r " + applicationName
		statementStatus  = execCommand(deleteRequest)

		if statementStatus == 1 :
			time.sleep(5)  # Delay for 5 seconds
			execCommand(deleteRequest)

		#check if really gone - POTENTIAL FOR INFINITE LOOP - Let the delete fail
		#if doesItExist("cf a ", applicationName, 0) :
		#	print("Unable to delete an application, trying again : " +deleteRequest)
		#	time.sleep(5)  # Delay for 5 seconds
		#	deleteExistingApplication(applicationName)

def deleteExistingService(serviceName):
	if doesItExist("cf s ", serviceName, 0) :
		deleteRequest = "cf delete-service -f " + serviceName
		statementStatus  = execCommand(deleteRequest)

		if statementStatus == 1 :
			time.sleep(5)  # Delay for 5 seconds
			execCommand(deleteRequest)

		#check if really gone - POTENTIAL FOR INFINITE LOOP - Let the delete fail
		#if doesItExist("cf s ", serviceName, 0) :
		#	print("Unable to delete an service, trying again: " +deleteRequest)
		#	deleteExistingService(serviceName)

def doesItExist(command, name, sectionNumber ) :
	'''handle duplicates due to similar spellings, avoid using regular expressions'''
	result, err, exitcode = call(command)
	#print("Result = " + result)
	#print("Err = " + err)
	#print(exitcode)
	rows = result.split('\n')
	#print("Rows = ")
	#print(rows)
	#print(rows.encode('utf-8'))
	if name in result:
		print(name + " does EXIST")
		return True
	else:
		print(name + " does not EXIST")
		return False
	#for row in rows:
	#	existingSection = row.split(" ")[sectionNumber]
	#	print(name)
	#	print("section= ")
	#	print(existingSection)
	#	if existingSection == name :
	#		return True

def createService(serviceName, serviceRequest):
	print("Create service if it does not exist: " +serviceName)
	print(serviceRequest)
	if doesItExist("cf s ", serviceName, 0) :
		print("Service Intance already exists:" + serviceName)
		return None
	else:
		statementStatus  = subprocess.call(serviceRequest, shell=True)
		if statementStatus == 1 :
			print("I am here 1")
			print("Error creating a service: " +serviceName)
			time.sleep(5)  # Delay for 5 seconds
			print("I am here after sleep 2")
			statementStatus  = subprocess.call(serviceRequest, shell=True)
			if statementStatus == 1 :
				print("Error creating a service: " +serviceName)
				sys.exit("Error creating a service instance: " +serviceName)
		else:
			#does it really exist yet
			print("I am here 2")
			if not doesItExist("cf s ", serviceName, 0) :
				time.sleep(5)
				print("I am here after sleep 2")
				createService(serviceName, serviceRequest)

def unbind(applicationName,serviceName):
	if doesItExist("cf a ", applicationName, 0) and doesItExist("cf a ", serviceName, 0):
		unbindRequest = "cf us " + applicationName + " " + serviceName
		print(unbindRequest)
		statementStatus  = subprocess.call(unbindRequest, shell=True)

		if statementStatus == 1 :
			print("Error unbinding an application: " + unbindRequest)
			time.sleep(5)  # Delay for 5 seconds
			statementStatus  = subprocess.call(unbindRequest, shell=True)
			if statementStatus == 1 :
				print("Error unbinding an application: " + unbindRequest)
				sys.exit("Error unbinding an application instance: " +applicationName + " from " + serviceName)


def call(cmd):
	"""Runs the given command locally and returns the output, err and exit_code, handles Pipes."""
	if "|" in cmd:
		cmd_parts = cmd.split('|')
	else:
		cmd_parts = []
		cmd_parts.append(cmd)
	i = 0
	p = {}
	for cmd_part in cmd_parts:
		cmd_part = cmd_part.strip()
		if i == 0:
		  p[i]=Popen(shlex.split(cmd_part),stdin=None, stdout=PIPE, stderr=PIPE)
		else:
		  p[i]=Popen(shlex.split(cmd_part),stdin=p[i-1].stdout, stdout=PIPE, stderr=PIPE)
		i = i +1
	(output, err) = p[i-1].communicate()
	exit_code = p[0].wait()

	return str(output).strip(), str(err), exit_code



# checkout submodules
def checkoutSubmodules():
	print("Pulling Submodules for " + os.getcwd())
	statementStatus  = subprocess.call('git submodule init', shell=True)
	if statementStatus == 1 :
		sys.exit("Error when init submodule ")
	statementStatus  = subprocess.call('git submodule update --init --remote', shell=True)
	if statementStatus == 1 :
		sys.exit("Error when updating submodules")

	return statementStatus

def updateGitModules(config):
	print("CurrentDir " + os.getcwd())
	if 'git@' in open('.gitmodules').read():
		config.updateGitModules='true'
		f1 = open('.gitmodules', 'r')
		f2 = open('.gitmodules.script', 'w')
		for line in f1:
			line = line.replace(':', '/')
			line = line.replace('git@', "https://")
			f2.write(line)
		f1.close()
		f2.close()
		shutil.copy(".gitmodules", ".gitmodules.bak")
		shutil.copy(".gitmodules.script", ".gitmodules")


def restoreGitModules(config):
	if ( os.path.isfile(".gitmodules.bak") ):
		print("restoring .gitmodules")
		shutil.copy(".gitmodules.bak", ".gitmodules")

def buildProject(mavenCommand,projectDir):
	statementStatus  = subprocess.call(mavenCommand, shell=True)
	if statementStatus == 1 :
		sys.exit("Error building the project "+projectDir)

	return statementStatus

class MultipartFormdataEncoder(object):
    def __init__(self):
        self.boundary = "FILEBOUNDARY"
        self.content_type = 'multipart/form-data; boundary={}'.format(self.boundary)

    @classmethod
    def u(cls, s):
        if sys.hexversion < 0x03000000 and isinstance(s, str):
            s = s.decode('utf-8')
        if sys.hexversion >= 0x03000000 and isinstance(s, bytes):
            s = s.decode('utf-8')
        return s

    def iter(self, fields, files):
        """
        fields is a sequence of (name, value) elements for regular form fields.
        files is a sequence of (name, filename, file-type) elements for data to be uploaded as files
        Yield body's chunk as bytes
        """
        encoder = codecs.getencoder('utf-8')
        print(fields)
        for (key, value) in fields:
            key = self.u(key)
            yield encoder('--{}\r\n'.format(self.boundary))
            yield encoder(self.u('Content-Disposition: form-data; name="{}"\r\n').format(key))
            yield encoder('\r\n')
            if isinstance(value, int) or isinstance(value, float):
                value = str(value)
            yield encoder(self.u(value))
            yield encoder('\r\n')
        for (key, filename, fpath) in files:
            key = self.u(key)
            filename = self.u(filename)
            yield encoder('--{}\r\n'.format(self.boundary))
            yield encoder(self.u('Content-Disposition: form-data; name="{}"; filename="{}"\r\n').format(key, filename))
            yield encoder('Content-Type: {}\r\n'.format(mimetypes.guess_type(filename)[0] or 'application/octet-stream'))
            yield encoder('\r\n')
            with open(fpath,'rb') as fd:
                buff = fd.read()
                yield (buff, len(buff))
            yield encoder('\r\n')
        yield encoder('--{}--\r\n'.format(self.boundary))

    def encode(self, fields, files):
        body = io.BytesIO()
        for chunk, chunk_len in self.iter(fields, files):
            body.write(chunk)
        return self.content_type, body.getvalue()

def evaluatePom(config, cfCommand, projectDir):
	try :
		print("\tevaluate Pom")
		curDir=os.getcwd()
		print ("\tCurrent Directory = " + os.getcwd())
		print ("\tProject Directory = " + projectDir)
		os.chdir(projectDir)
		print ("\tCurrent Directory = " + os.getcwd())
		f = open("pom.xml", 'r')
		f1 = f.read()
		f.close()
		print("\t============================")
		artifactIdTemp=re.search(r'<artifactId[^>]*>([^<]+)</artifactId>', f1)
		if artifactIdTemp:
			print("\t" + artifactIdTemp.group(1))
			config.artifactId=artifactIdTemp.group(1)
		else:
			sys.exit("Error getting artifactId from " + projectDir + "/pom.xml")
		versionTemp=re.search(r'<version[^>]*>([^<]+)</version>', f1)
		if versionTemp:
			print("\t" + versionTemp.group(1))
			config.jarVersion=versionTemp.group(1)
		else:
			sys.exit("Error getting jarVersion from " + projectDir + "/pom.xml")
		print("\tArtifactId derived from pom.xml = " + config.artifactId)
		print("\tJar Version derived from pom.xml=" + config.jarVersion)
	finally:
		print ("\tCurrent Directory = " + os.getcwd())
		os.chdir(curDir)
		print ("\tCurrent Directory = " + os.getcwd())
		print ("\txxx")


def getJarFromArtifactory(config, cfCommand, projectDir):
	print("\tFast install =" + config.fastinstall)

	if config.fastinstall == 'y' :
		print("\tretrieve jar from Artifactory")
		print("\tartifactory repo=" + config.artifactoryrepo)
		print("\tartifactory user =" + config.artifactoryuser)
		#print("\tartifactory pass =" + config.artifactorypass)
		curDir=os.getcwd()
		print ("\tCurrent Directory = " + os.getcwd())
		print ("\tProject Directory = " + projectDir)
		print('\tmvnsettings=' + config.mvnsettings)
		print('\tmavenRepo=' + config.mavenRepo)
		evaluatePom(config, cfCommand, projectDir)
		print("\tCopying artifacts..")

		f = open(config.mvnsettings, 'r')
		f1 = f.read()
		f.close()
		#print(f1)
		found = 0
		dom = parse(config.mvnsettings)
		serverlist = dom.getElementsByTagName("server")
		try :
			print("\tChdir to " + projectDir + " Current Directory = " + os.getcwd())
			os.chdir(projectDir)
			print("\tCurrent Directory = " + os.getcwd())
			print("")

			for aServer in serverlist:
				artifactory1 = aServer.getElementsByTagName("id")[0].firstChild.data
				artifactoryuser = aServer.getElementsByTagName("username")[0].firstChild.data
				artifactorypass = aServer.getElementsByTagName("password")[0].firstChild.data
				print( "\tserver id === " + artifactory1 )
				repolist = dom.getElementsByTagName("repository")
				for aRepo in repolist:
					artifactory2 = aRepo.getElementsByTagName("id")[0].firstChild.data
					artifactoryrepo = aRepo.getElementsByTagName("url")[0].firstChild.data
					print("\tREPOSITORY INFO :looking for=" + artifactory1 + " found=" + artifactory2 + ":" + artifactoryrepo)
					if artifactory1 == artifactory2 :
						print("\tArtifactory derived from maven settings.xml ==== " + artifactory2)
						print("\tArtifactory url from maven settings.xml ==== " + artifactoryrepo)
						print("\tArtifactory user derived from maven settings.xml ==== " + artifactoryuser)
						#print("Artifactory pass derived from maven settings.xml ==== " + artifactorypass)
						if artifactorypass.find("${") == 0 :
							print("\tpassword is set to an environment variable that was not found, moving on to next entry")
						else:
							try:
								os.stat("target")
							except:
								os.mkdir("target")
							urlOfJar=artifactoryrepo + "/com/ge/predix/solsvc/" + config.artifactId + "/" + config.jarVersion + "/" + config.artifactId + "-" + config.jarVersion + ".jar"
							print("/turlOfJar=" + urlOfJar)
							request = Request(urlOfJar)
							authString = artifactoryuser + ":" + artifactorypass
							base64string = base64.b64encode(bytearray(authString, 'UTF-8')).decode("ascii")
							request.add_header("Authorization", "Basic %s" % base64string)
							try:
								downloadFile="target/" + config.artifactId + "-" + config.jarVersion + ".jar"
								print("\tDownloading " + downloadFile)
								result = urlopen(request)
								with open(downloadFile, "wb") as local_file:
									local_file.write(result.read())
								print("\tFrom: url: " + artifactoryrepo)
								print("\tDownloading DONE")
								print("\t============================")
								found = 1
								break
							except URLError as err:
								e = sys.exc_info()[1]
								print("\tNot found in that repo, let's try another." + urlOfJar + " Error: %s" % e)
								found = 0
								continue
							except HTTPError as err:
								e = sys.exc_info()[1]
								print("\tNot found in that repo, let's try another." + urlOfJar + " Error: %s" % e)
								found = 0
								continue
					if found == 1:
						break
		finally:
			print("\tCurrent Directory = " + os.getcwd())
			os.chdir(curDir)
			print("\tCurrent Directory = " + os.getcwd())

		if found == 0:
			sys.exit("\tError copying artifact "+projectDir)

def pushProject(config, appName, cfCommand, projectDir, checkIfExists):
	print("****************** Running pushProject for "+ appName + " ******************" )

	if checkIfExists == "true" :
		#check if really gone
		if doesItExist("cf a ", applicationName, 0) :
			print(appName + " already exists, skipping push")
			return

	if config.fastinstall == 'y' :
		getJarFromArtifactory(config, cfCommand, projectDir)

	statementStatus = cfPush(appName, cfCommand)
	return statementStatus

def cfPush(appName, cfCommand):
		print("Deploying to CF..., Current Directory = " + os.getcwd())
		print(cfCommand)
		statementStatus  = subprocess.call(cfCommand, shell=True)
		if statementStatus == 1 :
			sys.exit("Error deploying the project " + appName)
		print("Deployment to CF done.")
		return statementStatus

def createPredixUAASecurityService(config):
	#create UAA instance
	uaa_payload_filename = 'uaa_payload.json'
	data = {}
	data['adminClientSecret'] = config.uaaAdminSecret

	#cross-os compatibility requires json to be in a file
	with open(uaa_payload_filename, 'w') as outfile:
		json.dump(data, outfile)
		outfile.close()

	uaaJsonrequest = "cf cs "+config.predixUaaService+" "+config.predixUaaServicePlan +" "+config.rmdUaaName+ " -c " + os.getcwd()+'/'+uaa_payload_filename
	createService(config.rmdUaaName,uaaJsonrequest)

def getVcapJsonForPredixBoot (config):
    print("cf env " + config.predixbootAppName)
    predixBootEnv = subprocess.check_output(["cf", "env" ,config.predixbootAppName])
    systemProvidedVars=predixBootEnv.decode('utf-8').split('System-Provided:')[1].split('No user-defined env variables have been set')[0]
    config.formattedJson = "[" + systemProvidedVars.replace("\n","").replace("'","").replace("}{","},{") + "]"
    #print ("formattedJson=" + config.formattedJson)

def addUAAUser(config, userId , password, email,adminToken):

	createUserBody = {"userName":"","password":"","emails":[{"value":""}]}
	createUserBody["userName"] = userId
	createUserBody["password"] = password
	createUserBody["emails"][0]['value'] = email

	createUserBodyStr = json.dumps(createUserBody)
	print(createUserBodyStr)

	statementStatusJson = invokeURLJsonResponse(config.UAA_URI+"/Users", {"Content-Type": "application/json", "Authorization": adminToken}, createUserBodyStr, "")
	if statementStatusJson.get('error'):
		statementStatus = statementStatusJson['error']
		statementStatusDesc = statementStatusJson['error_description']
	else :
		statementStatus = 'success'
		#statementStatusDesc = statementStatusJson['id']

	if statementStatus == 'success' or  'scim_resource_already_exists' not in statementStatusDesc :
		print(userId + "User is UAA ")
	else :
		sys.exit("Error adding Users "+statementStatusDesc )


def invokeURLJsonResponse(url, headers, data, method):
	responseCode = invokeURL(url, headers, data, method)
	return json.loads(open("json_output.txt").read())

def invokeURL(url, headers1, data, method):
	request = Request(url, headers=headers1)
	if method :
		request.get_method=lambda: method

	print ("Invoking URL ----" + request.get_full_url())
	print ("\tmethod ----" + request.get_method())
	print ("\t" + str(request.header_items()))
	print ("\tInput data=" + str(data))

	responseCode = 0
	try:
		if data :
			result = urlopen(request, data.encode('utf-8'))
		else :
			result = urlopen(request)
		print (request.data)
		with open("json_output.txt", "wb") as local_file:
			local_file.write(result.read())
			print ("\t*******OUTPUT**********" +  open("json_output.txt").read())
		responseCode = result.getcode()
		print ("\tRESPONSE=" + str(responseCode))
		print ("\t" + str(result.info()))
	except URLError as err:
		if err.code == 409:
			e = sys.exc_info()[0]
			print( "Resource found - continue: %s" % e)
			with open("json_output.txt", "wt") as local_file:
				local_file.write(json.dumps({'error': 'Resource found - continue','errorCode':+err.code,'error_description':'Resource found - continue'}))
				print ("\t*******OUTPUT**********" +  open("json_output.txt").read())
			responseCode = err.code
		elif err.code == 404:
			e = sys.exc_info()[0]
			print( "Resource not found - continue with create: %s" % e)
			with open("json_output.txt", "wt") as local_file:
				local_file.write(json.dumps({'error': 'Resource not found - continue','errorCode':+err.code,'error_description':'Resource not found - continue'}))
				print ("\t*******OUTPUT**********" +  open("json_output.txt").read())
			responseCode = err.code
		else :
			e = sys.exc_info()[0]
			print( "Error: %s" % e)
			e = sys.exc_info()[1]
			print( "Error: %s" % e)
			sys.exit()
	except HTTPError as err:
		if err.code == 409:
			e = sys.exc_info()[0]
			print( "Resource found - continue: %s" % e)
			with open("json_output.txt", "wt") as local_file:
				local_file.write(json.dumps({'error': 'Resource found - continue','errorCode':+err.code,'error_description':'Resource found - continue'}))
				print ("\t*******OUTPUT**********" +  open("json_output.txt").read())
			responseCode = err.code
		elif err.code == 404:
			e = sys.exc_info()[0]
			print( "Resource not found - continue with create: %s" % e)
			with open("json_output.txt", "wt") as local_file:
				local_file.write(json.dumps({'error': 'Resource not found - continue','errorCode':+err.code,'error_description':'Resource not found - continue'}))
				print ("\t*******OUTPUT**********" +  open("json_output.txt").read())
			responseCode = err.code
		else :
			e = sys.exc_info()[0]
			print( "Error: %s" % e)
			sys.exit()
	print ("\tInvoking URL Complete----" + request.get_full_url())
	print ("\tInvoking URL Complete with response code" + str(responseCode))
	return responseCode

def createClientIdAndAddUser(config):
	# setup the UAA login
	adminToken = processUAAClientId(config,config.UAA_URI+"/oauth/clients","POST")

	# Add users
	print("****************** Adding users ******************")
	addUAAUser(config, config.rmdUser1 , config.rmdUser1Pass, config.rmdUser1 + "@gegrctest.com",adminToken)
	addUAAUser(config, config.rmdAdmin1 , config.rmdAdmin1Pass, config.rmdAdmin1 + "@gegrctest.com",adminToken)

def createBindPredixACSService(config, rmdAcsName):
	acs_payload_filename = 'acs_payload.json'
	data = {}
	data['trustedIssuerIds'] = config.uaaIssuerId
	with open(acs_payload_filename, 'w') as outfile:
		json.dump(data, outfile)
		outfile.close()

	#create UAA instance
	acsJsonrequest = "cf cs "+config.predixAcsService+" "+config.predixAcsServicePlan +" "+rmdAcsName+ " -c "+ os.getcwd()+'/'+ acs_payload_filename
	print(acsJsonrequest)
	statementStatus  = subprocess.call(acsJsonrequest, shell=True)
	if statementStatus == 1 :
		sys.exit("Error creating a uaa service instance")

	statementStatus  = subprocess.call("cf bs "+config.predixbootAppName +" " + rmdAcsName , shell=True)
	if statementStatus == 1 :
		sys.exit("Error binding a uaa service instance to boot ")

	return statementStatus

def createGroup(config, adminToken,policyGrp):
	print("****************** Add Group ******************")
	createGroupBody = {"displayName":""}
	createGroupBody["displayName"] = policyGrp
	createGroupBodyStr = json.dumps(createGroupBody)
	print(createGroupBodyStr)

	statementStatusJson = invokeURLJsonResponse(config.UAA_URI+"/Groups", {"Content-Type": "application/json", "Authorization": adminToken}, createGroupBodyStr, "")

	if statementStatusJson.get('error'):
		statementStatus = statementStatusJson['error']
		statementStatusDesc = statementStatusJson['error_description']
	else :
		statementStatus = 'success'
		statementStatusDesc = 'success'

	if statementStatus == 'success' or  'scim_resource_exists' not in statementStatusDesc :
		print("Success creating or reusing the Group")
	else :
		sys.exit("Error Processing Adding Group on UAA "+statementStatusDesc )

def getGroupOrUserByDisplayName(uri, adminToken):
	getResponseJson=invokeURLJsonResponse(uri, {"Content-Type": "application/json", "Authorization": adminToken}, "", "")

	found = True
	statementStatus = 'success'

	if getResponseJson.get('totalResults') <=0 :
		statementStatus = 'not found'
		found = False

	return found, getResponseJson

def getGroup(config, adminToken ,grpname):
	return getGroupOrUserByDisplayName(config.UAA_URI+ "/Groups/?filter=displayName+eq+%22" + grpname + "%22&startIndex=1", adminToken)

def getUserbyDisplayName(config, adminToken ,username):
	return getGroupOrUserByDisplayName(config.UAA_URI+ "/Users/?attributes=id%2CuserName&filter=userName+eq+%22" + username + "%22&startIndex=1", adminToken)

def addAdminUserPolicyGroup(config, policyGrp,userName):

	adminToken = getTokenFromUAA(config, 1)
	if not adminToken :
		sys.exit("Error getting admin token from the UAA instance ")

	#check Get Group
	groupFound,groupJson = getGroup(config, adminToken,policyGrp)

	if not groupFound :
		createGroup(config,adminToken,policyGrp)
		groupFound,groupJson = getGroup(config, adminToken,policyGrp)



	userFound,userJson = getUserbyDisplayName(config,adminToken,userName)

	if not userFound :
		sys.exit(" User is not found in the UAA - error adding member to the group")

	members = []
	if groupJson.get('resources') :
		grpName = groupJson['resources'][0]
		if grpName.get('members') :
			groupMeberList = grpName.get('members')
			for groupMeber in groupMeberList:
				members.insert(0 ,groupMeber['value'])

	members.insert(0, userJson['resources'][0]['id'])

	print (' Member to be updated for the Group ,'.join(members))

	#update Group
	groupId = groupJson['resources'][0]['id']
	updateGroupBody = { "meta": {}, "schemas": [],"members": [],"id": "","displayName": ""}
	updateGroupBody["meta"] = groupJson['resources'][0]['meta']
	updateGroupBody["members"] = members
	updateGroupBody["displayName"] = groupJson['resources'][0]['displayName']
	updateGroupBody["schemas"] = groupJson['resources'][0]['schemas']
	updateGroupBody["id"] = groupId

	updateGroupBodyStr = json.dumps(updateGroupBody)
	uuaGroupURL = config.UAA_URI + "/Groups/"+groupId

	statementStatusJson = invokeURLJsonResponse(uuaGroupURL, {"Content-Type": "application/json", "Authorization": "%s" %adminToken, "if-match" : "*", "accept" : "application/json"}, updateGroupBodyStr, "PUT")
	if statementStatusJson.get('error'):
		statementStatus = statementStatusJson['error']
		statementStatusDesc = statementStatusJson['error_description']
	else :
		statementStatus = 'success'
		statementStatusDesc = 'success'

	if statementStatus == 'success' or  'Client already exists' not in statementStatusDesc :
		print ("User Successful adding " +userName + " to the group "+policyGrp)
	else :
		sys.exit("Error adding " +userName + " to the group "+policyGrp + " statementStatusDesc=" + statementStatusDesc )


def updateUserACS(config):
	addAdminUserPolicyGroup(config, "acs.policies.read",config.rmdAdmin1)
	addAdminUserPolicyGroup(config, "acs.policies.write",config.rmdAdmin1)
	addAdminUserPolicyGroup(config, "acs.attributes.read",config.rmdAdmin1)
	addAdminUserPolicyGroup(config, "acs.attributes.write",config.rmdAdmin1)

	addAdminUserPolicyGroup(config, "acs.policies.read",config.rmdUser1)
	addAdminUserPolicyGroup(config, "acs.attributes.read",config.rmdUser1)

def processUAAClientId (config,uuaClientURL,method):
	adminToken = getTokenFromUAA(config, 1)
	if not adminToken :
		sys.exit("Error getting admin token from the UAA instance ")

	print(config.clientScope)
	print(config.clientScopeList)

	createClientIdBody = {"client_id":"","client_secret":"","scope":[],"authorized_grant_types":[],"authorities":[],"autoapprove":["openid"]}
	createClientIdBody["client_id"] = config.rmdAppClientId
	createClientIdBody["client_secret"] = config.rmdAppSecret
	createClientIdBody["scope"] = config.clientScopeList
	createClientIdBody["authorized_grant_types"] = config.clientGrantType
	createClientIdBody["authorities"] = config.clientAuthoritiesList
	createClientIdBodyStr = json.dumps(createClientIdBody)
	print("****************** Creating client id ******************")

	# check if the client exists
	uaaClientResponseJson = invokeURLJsonResponse(config.UAA_URI+"/oauth/clients/"+config.rmdAppClientId, {"Content-Type": "application/json", "Authorization": adminToken}, '', 'GET')
	print("reponse from get client "+str(uaaClientResponseJson))
	if uaaClientResponseJson.get('error'):
			# failure since client does not exits, create the client
		uaaClientResponseJson = invokeURLJsonResponse(uuaClientURL, {"Content-Type": "application/json", "Authorization": adminToken}, createClientIdBodyStr, method)
		if uaaClientResponseJson.get('error'):
			statementStatus = uaaClientResponseJson['error']
			statementStatusDesc = uaaClientResponseJson['error_description']
		else :
			statementStatus = 'success'
			statementStatusDesc = 'success'
	else :
		statementStatus = 'success'
		statementStatusDesc = 'success'

	if statementStatus == 'success' or  'Client already exists' in statementStatusDesc :
		print("Success creating or reusing the Client Id")
		# setting client details on config
		config.clientScopeList=uaaClientResponseJson.get('scope')
		config.clientGrantType=uaaClientResponseJson.get('authorized_grant_types')
		config.clientAuthoritiesList=uaaClientResponseJson.get('authorities')
	else :
		sys.exit("Error Processing ClientId on UAA "+statementStatusDesc )

	return adminToken


def updateClientIdAuthorities(config):
	adminToken = getTokenFromUAA(config, 1)
	if not adminToken :
		sys.exit("Error getting admin token from the UAA instance ")
	print(config.clientScope)
	print(config.clientScopeList)

	createClientIdBody = {"client_id":"","client_secret":"","scope":[],"authorized_grant_types":[],"authorities":[],"autoapprove":["openid"]}
	createClientIdBody["client_id"] = config.rmdAppClientId
	createClientIdBody["client_secret"] = config.rmdAppSecret
	createClientIdBody["scope"] = config.clientScopeList
	createClientIdBody["authorized_grant_types"] = config.clientGrantType
	createClientIdBody["authorities"] = config.clientAuthoritiesList
	createClientIdBodyStr = json.dumps(createClientIdBody)

	print("****************** Updating client id ******************")
	uaaClientResponseJson = invokeURLJsonResponse(config.UAA_URI+"/oauth/clients/"+config.rmdAppClientId, {"Content-Type": "application/json", "Authorization": adminToken}, createClientIdBodyStr, "PUT")
	if uaaClientResponseJson.get('error'):
		statementStatus = uaaClientResponseJson['error']
		statementStatusDesc = uaaClientResponseJson['error_description']
	else :
		statementStatus = 'success'
		statementStatusDesc = 'success'

	#processUAAClientId(config,config.UAA_URI+"/oauth/clients/"+config.rmdAppClientId,"PUT")

def getTokenFromUAA(config, isAdmin):
	realmStr=""
	if isAdmin == 1:
		realmStr = "admin:"+config.uaaAdminSecret
	else :
		realmStr = config.rmdAppClientId+":"+config.rmdAppSecret
	authKey = base64.b64encode(bytearray(realmStr, 'UTF-8')).decode("ascii")
	queryClientCreds= "grant_type=client_credentials"

	getClientTokenResponseJson=invokeURLJsonResponse(config.uaaIssuerId + "?" + queryClientCreds, {"Content-Type": "application/x-www-form-urlencoded", "Authorization": "Basic %s" % authKey}, "", "")

	print("Client Token is "+getClientTokenResponseJson['token_type']+" "+getClientTokenResponseJson['access_token'])
	return (getClientTokenResponseJson['token_type']+" "+getClientTokenResponseJson['access_token'])

def createRefAppACSPolicyAndSubject(config,acs_zone_header):
	adminUserTOken = getTokenFromUAA(config, 0)
	acsJsonResponse = invokeURLJsonResponse(config.ACS_URI+'/v1/policy-set/'+config.acsPolicyName, {"Content-Type": "application/json", "Authorization": "%s" %adminUserTOken, "Predix-Zone-Id" : "%s" %acs_zone_header},"", "GET")
	print("ACS JSON Response"+str(acsJsonResponse))
	if acsJsonResponse.get('error'):
	  statementStatusDesc = acsJsonResponse['error_description']
	  statementStatus = 'not-found'
	else :
	  statementStatus = 'success'

	if('not-found' == statementStatus):
		invokeURL(config.ACS_URI+'/v1/policy-set/'+config.acsPolicyName, {"Content-Type": "application/json", "Authorization": "%s" %adminUserTOken, "Predix-Zone-Id" : "%s" %acs_zone_header}, open("./acs/rmd_app_policy.json").read(), "PUT")

	#acsSubjectCurl = 'curl -X PUT "'+config.ACS_URI+'/v1/subject/' + config.rmdAdmin1 + '"' + ' -d "@./acs/' + config.rmdAdmin1 + '_role_attribute.json"'+headers
	invokeURL(config.ACS_URI+'/v1/subject/' + config.rmdAdmin1, {"Content-Type": "application/json", "Authorization": "%s" %adminUserTOken, "Predix-Zone-Id" : "%s" %acs_zone_header}, open("./acs/" + config.rmdAdmin1 + "_role_attribute.json").read(), "PUT")
	#acsSubjectCurl = 'curl -X PUT "'+config.ACS_URI+'/v1/subject/' + config.rmdUser1 + '"' + ' -d "@./acs/"' + config.rmdUser1 + '"_role_attribute.json"'+headers
	invokeURL(config.ACS_URI+'/v1/subject/' + config.rmdUser1, {"Content-Type": "application/json", "Authorization": "%s" %adminUserTOken, "Predix-Zone-Id" : "%s" %acs_zone_header}, open("./acs/" + config.rmdUser1+ "_role_attribute.json").read(), "PUT")

def createAsssetInstance(config,rmdPredixAssetName ,predixAssetName ):
	getPredixUAAConfigfromVcaps(config)
	asset_payload_filename = 'asset_payload.json'
	uaaList = [config.uaaIssuerId]
	data = {}
	data['trustedIssuerIds'] = uaaList
	with open(asset_payload_filename, 'w') as outfile:
		json.dump(data, outfile)
		print(data)
		outfile.close()

		request = "cf cs "+predixAssetName+" "+config.predixAssetServicePlan +" "+rmdPredixAssetName+ " -c "+os.getcwd()+'/' +asset_payload_filename
		print ("Creating Service cmd "+request)
		statementStatus  = subprocess.call(request, shell=True)
		#if statementStatus == 1 :
			#sys.exit("Error creating a assset service instance")

def createTimeSeriesInstance(config,rmdPredixTimeSeriesName,predixTimeSeriesName):
	timeSeries_payload_filename = 'timeseries_payload.json'
	uaaList = [config.uaaIssuerId]
	data = {}
	data['trustedIssuerIds'] =uaaList
	with open(timeSeries_payload_filename, 'w') as outfile:
		json.dump(data, outfile)
		outfile.close()

	tsJsonrequest = "cf cs "+predixTimeSeriesName+" "+config.predixTimeSeriesServicePlan +" "+rmdPredixTimeSeriesName+ " -c "+os.getcwd()+'/'+timeSeries_payload_filename
	print ("Creating Service cmd "+tsJsonrequest)
	statementStatus  = subprocess.call(tsJsonrequest, shell=True)
	if statementStatus == 1 :
		sys.exit("Error creating a assset service instance")

def createAnalyticsRuntimeInstance(config,rmdPredixAnalyticsRuntime, predixAnalyticsRuntime):
	print("Creating Analytics runtime instance..")
	getPredixUAAConfigfromVcaps(config)
	asset_payload_filename = 'asset_payload.json'
	uaaList = [config.uaaIssuerId]
	data = {}
	data['trustedIssuerIds'] = uaaList
	with open(asset_payload_filename, 'w') as outfile:
		json.dump(data, outfile)
		print(data)
		outfile.close()

		request = "cf cs "+predixAnalyticsRuntime+" "+config.predixAnalyticsRuntimePlan +" "+rmdPredixAnalyticsRuntime+ " -c "+os.getcwd()+'/' +asset_payload_filename
		print ("Creating Service cmd "+request)
		statementStatus  = subprocess.call(request, shell=True)
		#if statementStatus == 1 :
			#sys.exit("Error creating a assset service instance")

def createAnalyticsCatalogInstance(config,rmdPredixAnalyticsCatalog, predixAnalyticsCatalog):
	print("Creating Analytics catalog instance..")
	getPredixUAAConfigfromVcaps(config)
	asset_payload_filename = 'asset_payload.json'
	uaaList = [config.uaaIssuerId]
	data = {}
	data['trustedIssuerIds'] = uaaList
	with open(asset_payload_filename, 'w') as outfile:
		json.dump(data, outfile)
		print(data)
		outfile.close()

		request = "cf cs "+predixAnalyticsCatalog+" "+config.predixAnalyticsCatalogPlan +" "+rmdPredixAnalyticsCatalog+ " -c "+os.getcwd()+'/' +asset_payload_filename
		print ("Creating Service cmd "+request)
		statementStatus  = subprocess.call(request, shell=True)
		#if statementStatus == 1 :
			#sys.exit("Error creating a assset service instance")

def createRabbitMQInstance(config):
	print("Creating Rabbit MQ instance..")
	request = "cf cs "+config.predixRabbitMQ+" "+config.predixRabbitMQPlan +" "+config.rmdRabbitMQ
	print ("Creating Service cmd "+request)
	statementStatus  = subprocess.call(request, shell=True)
	#if statementStatus == 1 :
		#sys.exit("Error creating a assset service instance")

def getPredixUAAConfigfromVcaps(config):
	if not hasattr(config,'uaaIssuerId') :
		getVcapJsonForPredixBoot(config)
		d = json.loads(config.formattedJson)
		config.uaaIssuerId =  d[0]['VCAP_SERVICES'][config.predixUaaService][0]['credentials']['issuerId']
		config.UAA_URI = d[0]['VCAP_SERVICES'][config.predixUaaService][0]['credentials']['uri']
		uaaZoneHttpHeaderName = d[0]['VCAP_SERVICES'][config.predixUaaService][0]['credentials']['zone']['http-header-name']
		uaaZoneHttpHeaderValue = d[0]['VCAP_SERVICES'][config.predixUaaService][0]['credentials']['zone']['http-header-value']
		print("****************** UAA configured As ******************")
		print ("\n uaaIssuerId = " + config.uaaIssuerId + "\n UAA_URI = " + config.UAA_URI + "\n "+uaaZoneHttpHeaderName+" = " +uaaZoneHttpHeaderValue+"\n")
		print("****************** ***************** ******************")


def getPredixACSConfigfromVcaps(config):
	if not hasattr(config,'ACS_URI') :
		getVcapJsonForPredixBoot(config)
		d = json.loads(config.formattedJson)
		config.ACS_URI = d[0]['VCAP_SERVICES'][config.predixAcsService][0]['credentials']['uri']
		config.acsPredixZoneHeaderName = d[0]['VCAP_SERVICES'][config.predixAcsService][0]['credentials']['zone']['http-header-name']
		config.acsPredixZoneHeaderValue = d[0]['VCAP_SERVICES'][config.predixAcsService][0]['credentials']['zone']['http-header-value']
		config.acsOauthScope = d[0]['VCAP_SERVICES'][config.predixAcsService][0]['credentials']['zone']['oauth-scope']


def bindService(applicationName , rmdServiceInstanceName):
	statementStatus  = subprocess.call("cf bs "+applicationName +" " + rmdServiceInstanceName , shell=True)
	if statementStatus == 1 :
		sys.exit("Error binding a "+rmdServiceInstanceName+" service instance to boot ")


def restageApplication(applicationName):
	statementStatus  = subprocess.call("cf restage "+applicationName, shell=True)
	if statementStatus == 1 :
		sys.exit("Error restaging a uaa service instance to boot")

def getAnalyticsRuntimeURLandZone(config):
	if not hasattr(config,'ANALYTICRUNTIME_ZONE') :
		print("parsing analytics runtime zone and uri from vcap")
		analyticsRuntimeUri = ''
		analyticsRuntimeZone = ''
		d = json.loads(config.formattedJson)
		analyticsRuntimeZone = d[0]['VCAP_SERVICES'][config.predixAnalyticsRuntime][0]['credentials']['zone-http-header-value']
		analyticsRuntimeUri = d[0]['VCAP_SERVICES'][config.predixAnalyticsRuntime][0]['credentials']['execution_uri']
		if "https" in analyticsRuntimeUri:
			config.ANALYTICRUNTIME_URI = analyticsRuntimeUri.split('https://')[1].strip()
		else :
			config.ANALYTICRUNTIME_URI = analyticsRuntimeUri.split('http://')[1].strip()
		config.ANALYTICRUNTIME_ZONE = analyticsRuntimeZone

def getAnalyticsCatalogURLandZone(config):
	if not hasattr(config,'CATALOG_ZONE') :
		catalogUri = ''
		catalogZone = ''
		d = json.loads(config.formattedJson)
		catalogZone = d[0]['VCAP_SERVICES'][config.predixAnalyticsCatalog][0]['credentials']['zone-http-header-value']
		catalogUri = d[0]['VCAP_SERVICES'][config.predixAnalyticsCatalog][0]['credentials']['catalog_uri']
		if "https" in catalogUri:
			config.CATALOG_URI = catalogUri.split('https://')[1].strip()
		else :
			config.CATALOG_URI = catalogUri.split('http://')[1].strip()
		config.CATALOG_ZONE = catalogZone

def getAssetURLandZone(config):
	if not hasattr(config,'ASSET_ZONE') :
		assetUrl = ''
		assetZone =''
		d = json.loads(config.formattedJson)
		assetZone = d[0]['VCAP_SERVICES'][config.predixAssetService][0]['credentials']['instanceId']
		assetUrl = d[0]['VCAP_SERVICES'][config.predixAssetService][0]['credentials']['uri']
		config.ASSET_ZONE = assetZone
		config.ASSET_URI = assetUrl

def getTimeseriesURLandZone(config):
	if not hasattr(config,'TS_ZONE') :
		timeseriesUrl = ''
		timeseriesZone =''
		d = json.loads(config.formattedJson)
		timeseriesZone = d[0]['VCAP_SERVICES'][config.predixTimeSeriesService][0]['credentials']['query']['zone-http-header-value']
		timeseriesUrl = d[0]['VCAP_SERVICES'][config.predixTimeSeriesService][0]['credentials']['query']['uri']
		config.TS_ZONE = timeseriesZone
		config.TS_URI = timeseriesUrl

def getClientAuthoritiesforAssetAndTimeSeriesService(config):
	d = json.loads(config.formattedJson)

	config.assetScopes = config.predixAssetService+".zones."+d[0]['VCAP_SERVICES'][config.predixAssetService][0]['credentials']['instanceId']+".user"
	#get Ingest authorities
	tsInjest = d[0]['VCAP_SERVICES'][config.predixTimeSeriesService][0]['credentials']['ingest']
	config.timeSeriesInjestScopes = tsInjest['zone-token-scopes'][0] +"," + tsInjest['zone-token-scopes'][1]
	# get query authorities
	tsQuery = d[0]['VCAP_SERVICES'][config.predixTimeSeriesService][0]['credentials']['query']
	config.timeSeriesQueryScopes = tsQuery['zone-token-scopes'][0] +"," + tsQuery['zone-token-scopes'][1]

	if hasattr(config,'ANALYTICRUNTIME_ZONE') :
		config.analyticRuntimeScopes = "analytics.zones." + config.ANALYTICRUNTIME_ZONE + ".user"
	#config.catalogScopes = "analytics.zones." + config.CATALOG_ZONE + ".user"

	config.clientAuthoritiesList.append(config.assetScopes)
	config.clientAuthoritiesList.append(config.timeSeriesInjestScopes)
	config.clientAuthoritiesList.append(config.timeSeriesQueryScopes)
	if hasattr(config,'analyticRuntimeScopes') :
		config.clientAuthoritiesList.append(config.analyticRuntimeScopes)
	#config.clientAuthoritiesList.append(config.catalogScopes)


	config.clientScopeList.append(config.assetScopes)
	config.clientScopeList.append(config.timeSeriesInjestScopes)
	config.clientScopeList.append(config.timeSeriesQueryScopes)
	if hasattr(config,'analyticRuntimeScopes') :
		config.clientScopeList.append(config.analyticRuntimeScopes)
	#config.clientScopeList.append(config.catalogScopes)

	print ("returning timeseries client zone scopes query -->"+config.timeSeriesQueryScopes + " timeSeriesInjestAuthorities -->"+config.timeSeriesInjestScopes )


def updateUAAUserGroups(config, serviceGroups):
	groups = serviceGroups.split(",")
	#print (groups)
	for group in groups:
		#print (group)
		addAdminUserPolicyGroup(config, group,config.rmdAdmin1Pass)
		addAdminUserPolicyGroup(config, group,config.rmdUser1Pass)

def findRedisService(config):
	#setup Redis
	result = []
	process = subprocess.Popen('cf m',
	    shell=True,
	    stdout=subprocess.PIPE,
	    stderr=subprocess.PIPE )
	for line in process.stdout:
	    result.append(line)
	errcode = process.returncode
	#print (errcode)
	search_redis = config.predixRedis
	for line in result:
		line1 = line.decode('utf-8')
		if(line1.find(search_redis) > -1):
			#print(line)
			config.predixRedis = line1.split()[0].strip()
			print ("Setting Redis config.predixRedis as ")
			print (config.predixRedis)

def getAuthorities(config):
	if not hasattr(config,'clientAuthoritiesList') :
		config.clientAuthoritiesList = list(config.clientAuthorities)
		config.clientScopeList = list(config.clientScope)

def updateClientAuthoritiesACS(config):
	getPredixACSConfigfromVcaps(config)
	# get ACS scopes
	config.clientAuthoritiesList.append(config.acsOauthScope)
	config.clientScopeList.append(config.acsOauthScope)
	# merge with exisiting client
	config.clientAuthoritiesList = config.clientAuthorities + list(set(config.clientAuthoritiesList) - set(config.clientAuthorities))
	config.clientScopeList =  config.clientScope + list(set(config.clientScopeList) - set(config.clientScope))
