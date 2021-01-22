#!groovy

def get_matlab_release(String job_name) {
  return 'R' + job_name[-5..-1]
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
      defaultValue: get_matlab_release(env.JOB_BASE_NAME),
      description: 'The release number of the Matlab to load e.g. R2019b.',
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
              tar --wildcards --strip-components=1 -xf \$archive_name */Horace
            '''
          }
          else {
            powershell './extract_horace_artifact.ps1'
          }

        }
      }
    }

    stage("Get-Horace-Euphonic-Interface") {
      steps {
        // .mltbx currently only available for Linux
        if (isUnix()) {
          script {
            // Creation of .mltbx is not yet in master, so use branch build
            copyArtifacts(
              filter: 'mltbx/*.mltbx',
              fingerprintArtifacts: true,
              projectName: "PACE-neutrons/horace-euphonic-interface/Branch-${env.JOB_BASE_NAME}",
              selector: lastSuccessful()
            )
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
          subject: "Linux failed pipeline: ${env.JOB_BASE_NAME}",
          body: "See ${env.BUILD_URL}"
        )
      }
    }

    cleanup {
      deleteDir()
    }

  }
}
