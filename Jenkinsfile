pipeline {
    agent any
    
    environment {
        // Harbor仓库信息 - 请替换为你的Harbor地址
        HARBOR_URL = '121.43.112.153:5000'
        HARBOR_PROJECT = 'mysql'
        // 镜像名称和标签
        IMAGE_NAME = 'mysql-custom'
        IMAGE_TAG = "${env.BUILD_NUMBER}-${env.GIT_COMMIT.substring(0,8)}"
        // 完整镜像路径
        FULL_IMAGE_NAME = "${HARBOR_URL}/${HARBOR_PROJECT}/${IMAGE_NAME}:${IMAGE_TAG}"
    }
    
    stages {
        stage('环境检查') {
            steps {
                echo "检查Docker环境..."
                sh "docker --version"
                sh "docker compose version"
                echo "检查网络连接..."
            }
        }
        
        stage('拉取代码') {
            steps {
                echo "从GitHub拉取最新代码..."
                git url: 'https://github.com/yinjianqiang1990/mysql.git',
                    branch: 'main'
            }
        }
        
        stage('代码质量检查') {
            steps {
                echo "检查配置文件格式..."
                sh "docker run --rm -v ${WORKSPACE}:/app alpine sh -c 'apk add --no-cache bash && bash -n /app/*.sh' || true"
                echo "检查SQL语法..."
                sh "docker run --rm -v ${WORKSPACE}:/sql mysql:8.0 mysql -u root -pRoot@123456 -e 'source /sql/init-script.sql' || true"
            }
        }
        
        stage('构建镜像') {
            steps {
                echo "开始构建MySQL镜像..."
                sh "docker build -t ${FULL_IMAGE_NAME} ."
                sh "docker images | grep ${IMAGE_NAME}"
            }
        }
        
        stage('推送镜像到Harbor') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'harbor-creds', passwordVariable: 'HARBOR_PWD', usernameVariable: 'HARBOR_USER')]) {
                    echo "登录Harbor仓库..."
                    sh "docker login -u ${HARBOR_USER} -p ${HARBOR_PWD} ${HARBOR_URL}"
                    
                    echo "推送镜像到Harbor..."
                    sh "docker push ${FULL_IMAGE_NAME}"
                    
                    echo "添加latest标签并推送..."
                    sh "docker tag ${FULL_IMAGE_NAME} ${HARBOR_URL}/${HARBOR_PROJECT}/${IMAGE_NAME}:latest"
                    sh "docker push ${HARBOR_URL}/${HARBOR_PROJECT}/${IMAGE_NAME}:latest"
                    
                    echo "登出Harbor..."
                    sh "docker logout ${HARBOR_URL}"
                }
            }
        }
        
        stage('部署MySQL容器') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'harbor-creds', passwordVariable: 'HARBOR_PWD', usernameVariable: 'HARBOR_USER')]) {
                    echo "从Harbor拉取最新镜像..."
                    sh "docker login -u ${HARBOR_USER} -p ${HARBOR_PWD} ${HARBOR_URL}"
                    sh "docker pull ${FULL_IMAGE_NAME}"
                    sh "docker logout ${HARBOR_URL}"
                }
                
                echo "停止并移除旧容器..."
                sh "docker stop mysql-server || true"
                sh "docker rm mysql-server || true"
                
                echo "启动新的MySQL容器..."
                sh """
                    docker run -d \
                        --name mysql-server \
                        -p 3306:3306 \
                        -v mysql-data:/var/lib/mysql \
                        -e MYSQL_ROOT_PASSWORD=123456 \
                        -e MYSQL_DATABASE=app_db \
                        -e MYSQL_USER=yin \
                        -e MYSQL_PASSWORD=123456 \
                        --restart always \
                        ${FULL_IMAGE_NAME}
                """
                
                echo "等待容器启动..."
                sh "sleep 10"
                
                echo "检查容器状态..."
                sh "docker ps | grep mysql-server"
                
                echo "验证MySQL服务..."
                sh "docker exec mysql-server mysql -u root -p123456 -e 'SELECT VERSION();'"
            }
        }
    }
    
    post {
        always {
            echo "清理工作空间..."
            cleanWs()
        }
        success {
            echo "流水线执行成功！MySQL已成功部署"
            // 可以添加邮件通知或其他通知方式
        }
        failure {
            echo "流水线执行失败！"
            // 可以添加失败通知
        }
    }
}
