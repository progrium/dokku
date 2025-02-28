package ps

import (
	"errors"
	"fmt"
	"path/filepath"
	"strings"

	"github.com/dokku/dokku/plugins/common"
	dockeroptions "github.com/dokku/dokku/plugins/docker-options"
	"github.com/gofrs/flock"
)

// CommandInspect displays a sanitized version of docker inspect for an app
func CommandInspect(appName string) error {
	if err := common.VerifyAppName(appName); err != nil {
		return err
	}

	scheduler := common.GetAppScheduler(appName)
	_, err := common.CallPlugnTrigger(common.PlugnTriggerInput{
		Trigger:     "scheduler-inspect",
		Args:        []string{scheduler, appName},
		StreamStdio: true,
	})
	return err
}

// CommandRebuild rebuilds an app from source
func CommandRebuild(appName string, allApps bool, parallelCount int) error {
	if allApps {
		return common.RunCommandAgainstAllApps(Rebuild, "rebuild", parallelCount)
	}

	if err := common.VerifyAppName(appName); err != nil {
		return err
	}

	return Rebuild(appName)
}

// CommandReport displays a ps report for one or more apps
func CommandReport(appName string, format string, infoFlag string) error {
	if len(appName) == 0 {
		apps, err := common.DokkuApps()
		if err != nil {
			if errors.Is(err, common.NoAppsExist) {
				common.LogWarn(err.Error())
				return nil
			}
			return err
		}
		for _, appName := range apps {
			if err := ReportSingleApp(appName, format, infoFlag); err != nil {
				return err
			}
		}
		return nil
	}

	return ReportSingleApp(appName, format, infoFlag)
}

// CommandRestart restarts an app
func CommandRestart(appName string, processName string, allApps bool, parallelCount int) error {
	if allApps {
		if processName != "" {
			return errors.New("Unable to restart all apps when specifying a process name")
		}
		return common.RunCommandAgainstAllApps(Restart, "restart", parallelCount)
	}

	if err := common.VerifyAppName(appName); err != nil {
		return err
	}

	if processName != "" {
		return RestartProcess(appName, processName)
	}

	return Restart(appName)
}

// CommandRestore starts previously running apps e.g. after reboot
func CommandRestore(appName string, allApps bool, parallelCount int) error {
	_, err := common.CallPlugnTrigger(common.PlugnTriggerInput{
		Trigger:     "pre-restore",
		StreamStdio: true,
	})
	if err != nil {
		return fmt.Errorf("Error running pre-restore: %s", err)
	}

	if allApps {
		if err := restorePrep(); err != nil {
			return err
		}

		return common.RunCommandAgainstAllApps(Restore, "restore", parallelCount)
	}

	if appName == "" {
		common.LogWarn("Restore specified without app, assuming --all")

		if err := restorePrep(); err != nil {
			return err
		}
		return common.RunCommandAgainstAllApps(Restore, "restore", parallelCount)
	}

	if err := common.VerifyAppName(appName); err != nil {
		return err
	}

	return Restore(appName)
}

// CommandRetire ensures old containers are retired
func CommandRetire(appName string) error {
	lockFile := filepath.Join(common.GetDataDirectory("ps"), "retire")
	scheduler := ""
	if appName == "" {
		scheduler = common.GetGlobalScheduler()
	} else {
		scheduler = common.GetAppScheduler(appName)
	}

	fileLock := flock.New(lockFile)
	locked, err := fileLock.TryLock()
	if err != nil {
		return &RetireLockFailed{&err}
	}
	defer fileLock.Unlock()

	if !locked {
		return &RetireLockFailed{}
	}

	common.LogInfo1("Retiring old containers and images")
	_, err = common.CallPlugnTrigger(common.PlugnTriggerInput{
		Trigger:     "scheduler-retire",
		Args:        []string{scheduler, appName},
		StreamStdio: true,
	})
	return err
}

// CommandScale gets or sets how many instances of a given process to run
func CommandScale(appName string, skipDeploy bool, processTuples []string) error {
	if err := common.VerifyAppName(appName); err != nil {
		return err
	}

	if len(processTuples) == 0 {
		return scaleReport(appName)
	}

	if !canScaleApp(appName) {
		return fmt.Errorf("App %s contains an app.json file with a formations key and cannot be manually scaled", appName)
	}

	common.LogInfo1(fmt.Sprintf("Scaling %s processes: %s", appName, strings.Join(processTuples, " ")))
	return scaleSet(scaleSetInput{
		appName:           appName,
		skipDeploy:        skipDeploy,
		clearExisting:     false,
		processTuples:     processTuples,
		deployOnlyChanged: true,
	})
}

// CommandSet sets or clears a ps property for an app
func CommandSet(appName string, property string, value string) error {
	if property == "restart-policy" {
		if !isValidRestartPolicy(value) {
			return errors.New("Invalid restart-policy specified")
		}

		common.LogInfo2Quiet(fmt.Sprintf("Setting %s to %s", property, value))
		return dockeroptions.SetDockerOptionForPhases(appName, []string{"deploy"}, "restart", value)
	}

	common.CommandPropertySet("ps", appName, property, value, DefaultProperties, GlobalProperties)
	return nil
}

// CommandStart starts an app
func CommandStart(appName string, allApps bool, parallelCount int) error {
	if allApps {
		return common.RunCommandAgainstAllApps(Start, "start", parallelCount)
	}

	if err := common.VerifyAppName(appName); err != nil {
		return err
	}

	return Start(appName)
}

// CommandStop stops an app
func CommandStop(appName string, allApps bool, parallelCount int) error {
	if allApps {
		return common.RunCommandAgainstAllApps(Stop, "stop", parallelCount)
	}

	if err := common.VerifyAppName(appName); err != nil {
		return err
	}

	return Stop(appName)
}
