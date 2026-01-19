conda create -n $PYTHON_INTERP python=3.12 \
  numpy \
  pandas \
  scikit-learn \
  pyspark \
  matplotlib \
  notebook \
  seaborn \
  jupyterlab \
  ipython \
  scipy \
  scikit-learn \
  tqdm \
  wget \
  flask \
  PyYAML \
  pytest \
  pyflakes \
  colorama \
  jsonschema \
  wget

conda activate $PYTHON_INTERP

# Ensure consistent with Spark install version
pip install pyspark==$SPARK_VERSION graphframes
pip install google-cloud-bigquery