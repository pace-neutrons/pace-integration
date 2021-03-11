#!groovy

def get_platform(String job_name) {
  // Get everything before last hyphen, this should be the name of the platform
  // e.g. 'Scientific-Linux-7'
  return job_name.tokenize('-')[0..-2].join('-')
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
      defaultValue: get_agent(env.JOB_BASE_NAME),
      description: 'The agent to execute the pipeline on.',
      name: 'AGENT',
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
    GenericTrigger(
      genericVariables: [
        [key: 'ref', value: '$.ref']
      ],

      causeString: 'Triggered on $ref',

      token: 'PACE_integration_webhook',

      printContributedVariables: true,
      printPostContent: true,

      silentResponse: false,

      regexpFilterText: '$ref',
      regexpFilterExpression: 'refs/head/' + env.JOB_BASE_NAME
    )
    pollSCM('')
    cron('H 5 * * 2-6')
  }

  stages {
    stage("Get-Horace") {
      steps {
        script {
          copyArtifacts(
            filter: 'build/Horace-*',
            fingerprintArtifacts: true,
            projectName: "PACE-neutrons/Horace/${env.JOB_BASE_NAME}",
            selector: lastSuccessful()
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
          copyArtifacts(
            filter: 'mltbx/*.mltbx',
            fingerprintArtifacts: true,
            // .mltbx is only being produced on 2019b builds
            projectName: 'PACE-neutrons/horace-euphonic-interface/' + get_platform(env.JOB_BASE_NAME) + '-2019b',
            selector: lastSuccessful()
            )
        }
      }
    }

    stage("Get-Euphonic") {
      steps {
        dir('Euphonic') {
          checkout([
            $class: 'GitSCM',
            branches: [[name: 'refs/heads/master']],
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
