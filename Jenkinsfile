#!groovy

@Library('PACE-shared-lib') import pace.common.PipeLineInfo

pli = new PipeLineInfo(env.JOB_BASE_NAME)

def is_master_build(String build_type) {
  if (build_type == 'Nightly') {
    return true
  } else {
    return false
  }
}

def get_readable_os(String os) {
  if (os == 'sl7') {
    return 'Scientific-Linux-7'
  } else if (os == 'win10' || os == 'pacewin') {
    return 'Windows-10'
  } else {
    return ''
  }
}

def get_build_info(String repo, String branch, String match_context) {
  def job_name
  def build_num
  def script_cmd = "python get_build_info.py ${repo} ${branch}"
  if (match_context) {
    script_cmd += " --match-context ${match_context}"
  }
  if (isUnix()) {
    build_info = sh(script: "module load conda/3 && ${script_cmd}", returnStdout: true)
  } else {
    build_info = bat(script: script_cmd, returnStdout: true)
  }
  println build_info
  // Index from the end to ignore any previous output
  job_name = build_info.tokenize(' |\n')[-2].trim()
  build_num = build_info.tokenize(' |\n')[-1].trim()
  return [job_name, build_num]
}

def get_artifact_url(String branch, String api_token) {
  def artifact_url
  def script_cmd = "python get_artifact_url.py ${branch} --api-token ${api_token}"
  if (isUnix()) {
    artifact_url = sh(script: "module load conda/3 && ${script_cmd}", returnStdout: true)
  } else {
    artifact_url = bat(script: script_cmd, returnStdout: true)
  }
  println artifact_url
  return artifact_url.tokenize(' |\n')[-1].trim()
}

properties([
  parameters([
    string(
      defaultValue: '',
      description: 'The version of Matlab to use e.g. 2019b.',
      name: 'MATLAB_VERSION',
      trim: true
    ),
    string(
      defaultValue: utilities.get_agent(pli.os),
      description: 'The agent to execute the pipeline on.',
      name: 'AGENT',
      trim: true
    ),
    string(
      defaultValue: '',
      description: 'The branch of Horace to test against',
      name: 'HORACE_BRANCH',
      trim: true
    ),
    string(
      defaultValue: '',
      description: 'The branch of Euphonic to test against',
      name: 'EUPHONIC_BRANCH',
      trim: true
    ),
    string(
      defaultValue: '',
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
    MATLAB_VERSION = utilities.get_param('MATLAB_VERSION', pli.matlab_release.replace('R', ''))
    CONDA_ENV_NAME = "py37_pace_integration_${env.MATLAB_VERSION}"
    CONDA_PY_VERSION = "3.7"
    HORACE_BRANCH = utilities.get_param('HORACE_BRANCH', 'master')
    EUPHONIC_BRANCH = utilities.get_param('EUPHONIC_BRANCH', 'master')
    HORACE_EUPHONIC_INTERFACE_BRANCH = utilities.get_param('HORACE_EUPHONIC_INTERFACE_BRANCH', 'master')
  }

  triggers {
    cron(is_master_build(pli.build_type) ? 'H 5 * * 2-6' : '')
  }

  stages {
    stage("Get-PACE-jenkins-shared-library") {
      steps {
        dir('PACE-jenkins-shared-library') {
          checkout([
            $class: 'GitSCM',
            branches: [[name: "refs/heads/main"]],
            extensions: [[$class: 'WipeWorkspace']],
            userRemoteConfigs: [[url: 'https://github.com/pace-neutrons/PACE-jenkins-shared-library.git']]
          ])
        }
      }
    }

    stage("Get-Horace") {
      steps {
        script {
          def project_name = "PACE-neutrons/Horace/"
          def selec
          if (is_master_build(pli.build_type) || env.HORACE_BRANCH == 'master') {
            selec = lastSuccessful()
            project_name = project_name + get_readable_os(pli.os) + "-${env.MATLAB_VERSION}"
          } else {
            def (job_name, build_num) = get_build_info(
              'Horace', env.HORACE_BRANCH, get_readable_os(pli.os) + "-${env.MATLAB_VERSION}")
            selec = specific(buildNumber: build_num)
            project_name = project_name + job_name
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
            powershell './powershell_scripts/extract_artifact.ps1 "build/Horace-*.zip" "Horace"'
          }

        }
      }
    }

    stage("Get-Horace-Euphonic-Interface-Matlab") {
      steps {
        script {
          withCredentials([string(credentialsId: 'GitHub_API_Token',
                                  variable: 'api_token')]) {
            def artifact_url = get_artifact_url(env.HORACE_EUPHONIC_INTERFACE_BRANCH, api_token)
            if (isUnix()) {
              sh """
                curl -LO -H "Authorization: token ${api_token}" --request GET ${artifact_url}
                unzip zip
              """
            }
            else {
              powershell """
                [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
                Invoke-RestMethod -Uri ${artifact_url} \
                                  -Headers @{Authorization = "token ${api_token}"} \
                                  -Method 'GET' \
                                  -ContentType 'application/zip' \
                                  -OutFile 'horace_euphonic_interface.mltbx.zip'
                ./powershell_scripts/extract_artifact.ps1 "horace_euphonic_interface.mltbx.zip" "horace_euphonic_interface.mltbx"
              """
            }
          }
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
            sh """
              module load conda/3 &&
              conda create --name \$CONDA_ENV_NAME python=\$CONDA_PY_VERSION -y
            """
          }
          else {
            powershell './PACE-jenkins-shared-library/powershell_scripts/create_conda_environment.ps1'
            }
          }
      }
    }

    stage("Install-Euphonic") {
      steps {
        dir('Euphonic') {
	  // Note psutil is euphonic_sqw_models dependency
          script {
            if (isUnix()) {
              sh '''
                module load conda/3 &&
                module load gcc &&
                conda activate \$CONDA_ENV_NAME &&
                python -mpip install --upgrade pip &&
                python -mpip install psutil &&
                python -mpip install numpy &&
                python -mpip install .
              '''
            }
            else {
              bat """
                set
                echo %cd%
                cd "%VS140COMNTOOLS%"
                dir /s vcvar*
                CALL "%VS140COMNTOOLS%vcvarsall.bat" x86_amd64
                CALL conda.bat activate %CONDA_ENV_NAME%
                where python
                python -mpip install --upgrade pip
                python -mpip install psutil
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
              powershell './PACE-jenkins-shared-library/powershell_scripts/execute_matlab_command.ps1 "setup_and_run_tests"'
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
          if (is_master_build(pli.build_type)) {
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
