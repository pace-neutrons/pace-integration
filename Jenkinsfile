#!groovy

def is_master_build(String job_name) {
  // Master builds start with the platform, branch builds start with
  // 'Branch-' or 'PR-'
  if (job_name.tokenize('-')[0] in ['Branch', 'PR']) {
    return false
  } else {
    return true
  }
}

def get_platform(String job_name) {
  // Get name of the platform e.g. 'Scientific-Linux-7'
  def idxi
  if (is_master_build(job_name)) {
    idxi = 0
  } else {
    idxi = 1
  }
  return job_name.tokenize('-')[idxi..-2].join('-')
}

def get_matlab_version(String job_name) {
  return job_name[-5..-1]
}

def get_agent(String job_name) {
  if (get_platform(job_name) == 'Scientific-Linux-7') {
    withCredentials([string(credentialsId: 'sl7_agent', variable: 'agent')]) {
      return "${agent}"
    }
  } else if (get_platform(job_name) == 'Windows-10') {
    withCredentials([string(credentialsId: 'win10_agent', variable: 'agent')]) {
      return "${agent}"
    }
  } else {
    return ''
  }
}

properties([
  parameters([
    string(
      defaultValue: get_matlab_version(env.JOB_BASE_NAME),
      description: 'The version of Matlab to use e.g. 2019b.',
      name: 'MATLAB_VERSION',
      trim: true
    ),
    string(
      defaultValue: get_platform(env.JOB_BASE_NAME),
      description: 'The human-readable platform to execute the pipeline on.',
      name: 'PLATFORM',
      trim: true
    ),
    string(
      defaultValue: get_agent(env.JOB_BASE_NAME),
      description: 'The agent to execute the pipeline on.',
      name: 'AGENT',
      trim: true
    ),
    string(
      defaultValue: 'master',
      description: 'The branch of Horace to test against',
      name: 'HORACE_BRANCH',
      trim: true
    ),
    string(
      defaultValue: 'master',
      description: 'The branch of Euphonic to test against',
      name: 'EUPHONIC_BRANCH',
      trim: true
    ),
    string(
      defaultValue: 'master',
      description: 'The branch of horace-euphonic-interface to test against',
      name: 'HORACE_EUPHONIC_INTERFACE_BRANCH',
      trim: true
    )
  ])
])

pipeline {

  agent {
    label env.AGENT
  }

  environment {
    CONDA_ENV_NAME = "py36_pace_integration_${env.MATLAB_VERSION}"
  }

  triggers {
    cron(is_master_build(env.JOB_BASE_NAME) ? 'H 5 * * 2-6' : '')
  }

  stages {
    stage("Get-Horace") {
      steps {
        script {
          def project_name = "PACE-neutrons/Horace/"
          def selec
          if (is_master_build(env.JOB_BASE_NAME) || env.HORACE_BRANCH == 'master') {
            selec = lastSuccessful()
            project_name = project_name + "${env.PLATFORM}-${env.MATLAB_VERSION}"
          } else {
            def build_num
            def script_cmd = "python get_build_number.py Horace ${env.HORACE_BRANCH} --match-build"
            if (isUnix()) {
              build_num = sh(script: "module load conda/3 && ${script_cmd}", returnStdout: true)
            } else {
              build_num = bat(script: script_cmd, returnStdout: true)
            }
            selec = specific(buildNumber: env.HORACE_BUILD_NUM)
            project_name = project_name + env.JOB_BASE_NAME
          }
          copyArtifacts(
            filter: 'build/Horace-*',
            fingerprintArtifacts: true,
            projectName: project_name,
            selector: selec
          )
          if (isUnix()) {
            sh '''
              archive_name="\$(find -name Horace-*.tar.gz)"
              mkdir Horace && tar --strip-components=1 -xf \$archive_name -C Horace
            '''
          }
          else {
            powershell './powershell_scripts/extract_horace_artifact.ps1'
          }

        }
      }
    }

    stage("Get-Horace-Euphonic-Interface-Matlab") {
      steps {
        script {
          def build_num
          def script_cmd = "python get_build_number.py horace-euphonic-interface ${env.HORACE_EUPHONIC_INTERFACE_BRANCH}"
          if (isUnix()) {
            build_num = sh(script: "module load conda/3 && ${script_cmd}", returnStdout: true)
          } else {
            build_num = bat(script: script_cmd, returnStdout: true)
          }
          // horace-euphonic-interface doesn't have any mex code, so using
          // Scientific-Linux-7-2019b should be ok. Currently the toolbox doesn't build
          // on 2018b and statuses aren't reported for Windows builds
          copyArtifacts(
            filter: 'mltbx/*.mltbx',
            fingerprintArtifacts: true,
            projectName: 'PACE-neutrons/horace-euphonic-interface/Scientific-Linux-7-2019b',
            selector: specific(buildNumber: env.HORACE_EUPHONIC_INTERFACE_BUILD_NUM)
            )
        }
      }
    }

    stage("Get-Euphonic") {
      steps {
        dir('Euphonic') {
          checkout([
            $class: 'GitSCM',
            branches: [[name: "refs/heads/${env.EUPHONIC_BRANCH}"]],
            extensions: [[$class: 'WipeWorkspace']],
            userRemoteConfigs: [[url: 'https://github.com/pace-neutrons/Euphonic.git']]
          ])
        }
      }
    }

    stage("Create-Conda-Environment") {
      steps {
        script {
          if (isUnix()) {
            sh '''
              module load conda/3 &&
              conda create --name \$CONDA_ENV_NAME python=3.6 -y
            '''
          }
          else {
            powershell './powershell_scripts/create_conda_environment.ps1'
            }
          }
      }
    }

    stage("Install-Euphonic") {
      steps {
        dir('Euphonic') {
          script {
            if (isUnix()) {
              sh '''
                module load conda/3 &&
                module load gcc &&
                conda activate \$CONDA_ENV_NAME &&
                python -mpip install --upgrade pip &&
                python -mpip install numpy &&
                python -mpip install .
              '''
            }
            else {
              bat """
                CALL "%VS2019_VCVARSALL%" x86_amd64
                CALL conda activate %CONDA_ENV_NAME%
                python -mpip install --upgrade pip
                python -mpip install numpy
                python -mpip install .
              """
            }
          }
        }
      }
    }

    stage("Set-Up-Matlab-And-Run-Tests") {
      steps {
        script {
          if (isUnix()) {
            sh '''
              module load conda/3 &&
              conda activate \$CONDA_ENV_NAME &&
              export PYTHON_EX_PATH=`which python` &&
              module load matlab/R\$MATLAB_VERSION &&
              matlab -nosplash -nodesktop -batch "setup_and_run_tests"
            '''
          }
          else {
              powershell './powershell_scripts/execute_matlab_tests.ps1'
          }
        }
      }
    }
  }
  post {
    unsuccessful {
      withCredentials([string(credentialsId: 'Euphonic_contact_email', variable: 'euphonic_email'),
                       string(credentialsId: 'Horace_contact_email', variable: 'horace_email')]){
        script {
          if (false) {
            mail (
              to: "${euphonic_email},${horace_email}",
              subject: "PACE integration pipeline failed: ${env.JOB_BASE_NAME}",
              body: "See ${env.BUILD_URL}"
            )
          }
        }
      }
    }

    cleanup {
      deleteDir()
    }

  }
}
