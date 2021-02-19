#!groovy

def get_matlab_version(String job_name) {
  return job_name[-5..-1]
}

def get_agent(String job_name) {
  if (job_name.contains('Scientific-Linux-7')) {
    withCredentials([string(credentialsId: 'sl7_agent', variable: 'agent')]) {
      return "${agent}"
    }
  } else if (job_name.contains('Windows-10')) {
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

  triggers {
    upstream(
      upstreamProjects: "PACE-neutrons/Horace/Scientific-Linux-7-2019b," +
                        "PACE-neutrons/Euphonic/Euphonic Linux Pipeline/master," +
                        "PACE-neutrons/horace-euphonic-interface/Branch-Scientific-Linux-7-2019b",
      threshold: hudson.model.Result.SUCCESS)
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
            powershell './extract_horace_artifact.ps1'
          }

        }
      }
    }

    stage("Get-Horace-Euphonic-Interface-Matlab") {
      steps {
        script {
          // Creation of .mltbx is not yet in master, so use branch build
          copyArtifacts(
            filter: 'mltbx/*.mltbx',
            fingerprintArtifacts: true,
            // Also .mltbx not being created on Windows builds yet, so for now use Linux
            projectName: "PACE-neutrons/horace-euphonic-interface/Branch-Scientific-Linux-7-2019b",
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

    stage("Install-Euphonic") {
      steps {
        dir('Euphonic') {
          script {
            if (isUnix()) {
              sh '''
                module load conda/3 &&
                module load gcc &&
                conda create --name py python=3.6 -y &&
                conda activate py &&
                python -mpip install --upgrade pip &&
                python -mpip install numpy &&
                python -mpip install .
              '''
            }
            else {
              bat """
                CALL conda remove --name py36_pace_integration_%MATLAB_VERSION% --all -y
                CALL conda create --name py36_pace_integration_%MATLAB_VERSION% python=3.6 -y
                CALL "%VS2019_VCVARSALL%" x86_amd64
                CALL conda activate py36_pace_integration_%MATLAB_VERSION%
                python -mpip install --upgrade pip
                python -mpip install numpy
                python -mpip install .
              """
            }
          }
        }
      }
    }

    stage("Get-Horace-Euphonic-Interface-Python") {
      steps {
        dir('horace-euphonic-interface') {
          checkout([
            $class: 'GitSCM',
            branches: [[name: 'refs/heads/new_interface']],
            extensions: [[$class: 'WipeWorkspace']],
            userRemoteConfigs: [[url: 'https://github.com/pace-neutrons/horace-euphonic-interface.git']]
          ])
        }
      }

    }

    stage("Install-Horace-Euphonic-Interface-Python") {
      steps {
        dir('horace-euphonic-interface') {
          script {
            if (isUnix()) {
              sh '''
                module load conda/3 &&
                conda activate py &&
                python -mpip install .
              '''
            }
            else {
              bat """
                CALL conda activate py36_pace_integration_%MATLAB_VERSION%
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
              conda activate py &&
              export PYTHON_EX_PATH=`which python` &&
              module load matlab/R\$MATLAB_VERSION &&
              matlab -nosplash -nodesktop -batch "setup_and_run_tests"
            '''
          }
          else {
              powershell './execute_matlab_tests.ps1'
          }
        }
      }
    }
  }
  post {
    unsuccessful {
      script {
        mail (
          to: "rebecca.fair@stfc.ac.uk",
          subject: "PACE pipeline failed: ${env.JOB_BASE_NAME}",
          body: "See ${env.BUILD_URL}"
        )
      }
    }

    cleanup {
      deleteDir()
    }

  }
}
