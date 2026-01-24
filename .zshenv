export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PYTHON_INTERP=s4p3.12
export SPARK_VERSION=4.1.1
# Spark
export SPARK_HOME=/opt/spark
export PATH="$PATH:$SPARK_HOME/bin"

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
