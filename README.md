# Description

This role configures a [Launchd scheduled job](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/ScheduledJobs.html) for running a provided script or command.

# Configuration

```yml
launchd_timer_name: 'my-test'
launchd_timer_description: 'Just a timer creation test.'
launchd_timer_user: 'root'
launchd_timer_frequency: '172800' # 48 hours
launchd_timer_timeout_sec: 120
launchd_timer_work_dir: '/tmp/somedir'
launchd_timer_environment:
  MY_ENV_VAR: 'some_value'
launchd_timer_script_content: |
  #!/usr/bin/env bash
  echo "My Timer Script!"
```
The `frequency` accepts seconds for `StartInterval`. There is no support for using `StartCalendarInterval` yet.

## Startup and Restarts

Automatic restarts can be enabled using:
```yml
launchd_timer_keep_alive: false
```
You can also start the timer at boot or at creation time:
```yml
launchd_timer_start_on_boot: true
launchd_timer_start_on_creation: true
```

## Consul Metadata

You can also customize the Consul service definition:
```
launchd_timer_consul_service_id: 'my-test-abc'
launchd_timer_consul_service_name: 'my-test'
launchd_timer_consul_extra_tags: ['test', 'abc']
launchd_timer_consul_meta: { my_meta: 'metadata' }
```
The service runs the [`check.sh`](templates/check.sh.j2) script to verify timer health..

# Usage

The the timer starts the service with configured frequency.

The state of the timer can be checked in a limited capcity using `launchctl`:
```
 > sudo launchctl my-test
{
	"StandardOutPath" = "/var/log/my-test.out.log";
	"LimitLoadToSessionType" = "System";
	"StandardErrorPath" = "/var/log/my-test.err.log";
	"Label" = "my-test";
	"OnDemand" = false;
	"LastExitStatus" = 0;
	"Program" = "/usr/local/bin/my-test";
	"ProgramArguments" = ();
};
```
