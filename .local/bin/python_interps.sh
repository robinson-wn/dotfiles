conda create -n $PYTHON_INTERP python=3.12 \
  numpy \
  pandas \
  scikit-learn \
  pyspark \
  matplotlib \
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
  jsonschema

conda activate $PYTHON_INTERP

# Ensure consistent with Spark install version
pip install pyspark==3.5.6
pip install google-cloud-bigquery