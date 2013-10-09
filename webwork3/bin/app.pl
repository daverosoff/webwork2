#!/usr/bin/env perl
use Dancer;
use Dancer::Plugin::Database;
use WeBWorK::DB;
use WeBWorK::CourseEnvironment;
use Routes::Course;
use Routes::Library;
use Routes::ProblemSets;
use Routes::User;
use Routes::Settings;
use Routes::PastAnswers;




set serializer => 'JSON';

hook 'before' => sub {

    for my $key (keys(%{request->params})){
    	my $value = defined(params->{$key}) ? params->{$key} : ''; 
    	debug($key . " : " . $value);
    }

	var ce => WeBWorK::CourseEnvironment->new({webwork_dir => config->{webwork_dir}, courseName=> session->{course}});
	var db => new WeBWorK::DB(vars->{ce}->{dbLayout});

};

## right now, this is to help handshaking between the original webservice and dancer.  
## it does nothing except sets the session using the hook 'before' above. 

get '/login' => sub {
	
	return {msg => "If you get this message all should have worked"};
};

any ['get','put','post','del'] => '/**' => sub {
	
	debug "In uber route";

	checkRoutePermissions();
	authenticate();

	pass;
};




get '/app-info' => sub {
	return {
		environment=>config->{environment},
		port=>config->{port},
		content_type=>config->{content_type},
		startup_info=>config->{startup_info},
		server=>config->{server},
		appdir=>config->{appdir},
		template=>config->{template},
		logger=>config->{logger},
		session=>config->{session},
		session_expires=>config->{session_expires},
		session_name=>config->{session_name},
		session_secure=>config->{session_secure},
		session_is_http_only=>config->{session_is_http_only},
		
	};
};

sub getCourseEnvironment {
	my $courseID = shift;

	  return WeBWorK::CourseEnvironment->new({
	 	webwork_url         => "/Volumes/WW_test/opt/webwork/webwork2",
	 	webwork_dir         => "/Volumes/WW_test/opt/webwork/webwork2",
	 	pg_dir              => "/Volumes/WW_test/opt/webwork/pg",
	 	webwork_htdocs_url  => "/Volumes/WW_test/opt/webwork/webwork2_files",
	 	webwork_htdocs_dir  => "/Volumes/WW_test/opt/webwork/webwork2/htdocs",
	 	webwork_courses_url => "/Volumes/WW_test/opt/webwork/webwork2_course_files",
	 	webwork_courses_dir => "/Volumes/WW_test/opt/webwork/webwork2/courses",
	 	courseName          => $courseID,
	 });
}

sub authenticate {
		## need to check that the session hasn't expired. 

    debug "Checking if session->{user} is defined";
    debug session->{user};

    if (! defined(session->{user})) {
    	if (defined(params->{user})){
	    	session->{user} = params->{user};
    	} else {
    		send_error("The user is not defined. You may need to authenticate again",401);	
    	}
	}

	if (! defined(session->{course})) {
		if (defined(params->{course})) {
			session->{course} = params->{course};
		} else {
			send_error("The course has not been defined.  You may need to authenticate again",401);	
		}

	}

	# debug "Checking if session->{session_key} is defined";
	# debug session->{session_key};


	if(! defined(session->{session_key})){
		if (defined(session->{course})){
			debug session->{course}.'_key';		
			my $session_key = database->quick_select(session->{course}.'_key', { user_id => session->{user} });
			if ($session_key->{key_not_a_keyword} eq param('session_key')) {
				session->{session_key} = params->{session_key};
			} 
		}
	}

	if(! defined(session->{session_key})){
		send_error("The session_key has not been defined or is not correct.  You may need to authenticate again",401);	
	}

	debug "Checking if session->{permission} is defined";
	debug session->{permission};


	if (defined(session->{course}) && ! defined(session->{permission})){
		my $permission = database->quick_select(session->{course}.'_permission', { user_id => session->{user} });
		session->{permission} = $permission->{permission};		
	}

}

sub checkRoutePermissions {

	debug "Checking Route Permissions";

	debug request->path;

}

# my $permissions = {
# 	"get|/Library/subjects" => 
# }


Dancer->dance;
