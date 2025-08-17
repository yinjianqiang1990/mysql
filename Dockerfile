FROM mysql:8.0

# 维护者信息
LABEL maintainer="yinjianqiang"

# 设置环境变量
ENV MYSQL_ROOT_PASSWORD=123456
ENV MYSQL_DATABASE=app_db
ENV MYSQL_USER=yin
ENV MYSQL_PASSWORD=123456

# 复制自定义配置文件
COPY my.cnf /etc/mysql/conf.d/

# 复制初始化SQL脚本
COPY init-script.sql /docker-entrypoint-initdb.d/

# 赋予脚本执行权限
RUN chmod 644 /etc/mysql/conf.d/my.cnf && \
    chmod 644 /docker-entrypoint-initdb.d/init-script.sql

# 暴露端口
EXPOSE 3306

# 设置数据卷
VOLUME ["/var/lib/mysql"]
