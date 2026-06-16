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

The `frequency` accepts seconds for `StartInterval`.

## Scheduling on a Calendar Interval

Alternatively, you can schedule the timer on a calendar interval using
`launchd_timer_start_calendar_interval`. When set, it takes precedence over
`launchd_timer_frequency` (which is then ignored). It maps directly to launchd's
[`StartCalendarInterval`](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/ScheduledJobs.html)
and accepts the keys `Minute`, `Hour`, `Day`, `Weekday`, `Month`
(any omitted key means "every"):

```yml
# Run every Monday at 03:00
launchd_timer_start_calendar_interval:
  Weekday: 1
  Hour: 3
  Minute: 0
```

You can also pass a list of dicts for multiple schedules:

```yml
launchd_timer_start_calendar_interval:
  - { Weekday: 1, Hour: 3, Minute: 0 }
  - { Weekday: 4, Hour: 3, Minute: 0 }
```

**Note:** if the machine is asleep at the scheduled time the job runs on wake,
but if it is powered off the run is skipped until the next scheduled time.

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
