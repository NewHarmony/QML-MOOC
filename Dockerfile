FROM jupyter/minimal-notebook
USER root
RUN mkdir /home/qmlmooc
WORKDIR /home/qmlmooc
# Create working directory
RUN mkdir workdir && cd workdir
#Add tools
RUN \
  apt-get -y update && apt-get install -y \
  apt-utils \
  curl 
# Add IBM qiskit
RUN \
  pip install --no-cache-dir \
  qiskit \ 
  qiskit-terra[visualization]
# Add dwave ocean
RUN pip --no-cache-dir install dwave-ocean-sdk
# Add Rigetti forest/pyquil
RUN \
  pip install --no-cache-dir pyquil &&\
  curl -O http://downloads.rigetti.com/qcs-sdk/forest-sdk-2.23.0-linux-deb.tar.bz2 &&\
  tar -xf forest-sdk-2.23.0-linux-deb.tar.bz2 &&\
  echo "y" | ./forest-sdk-2.23.0-linux-deb/forest-sdk-2.23.0-linux-deb.run &&\
  rm forest-sdk-2.23.0-linux-deb.tar.bz2 &&\
  rm -r ./forest-sdk-2.23.0-linux-deb
# Add additional Rigetti modules to support other notebook libraries
RUN \
  pip install --no-cache-dir \
  quantum-grove \
  forest-benchmarking
# Add symlink. Not elegant, but qvm wont't start without it. Check future releases of qvm for necessity
RUN ln -s /usr/lib/x86_64-linux-gnu/libffi.so.7 /usr/lib/x86_64-linux-gnu/libffi.so.6
# Add qutip
RUN conda install -c conda-forge qutip
# Add Pennylane
RUN pip --no-cache-dir install pennylane
# Add plotting
RUN \
  apt-get -y update && apt-get -y install \
  texlive-latex-base \
  texlive-latex-extra \
  imagemagick &&\
  rm -rf /var/lib/apt/lists
# configure the imageMagick policy file
RUN \
  sed 's%<policy domain="coder" rights="none" pattern="PDF" />%<!-- deleted policy for PDF -->%' /etc/ImageMagick-6/policy.xml > ./new_policy.xml &&\
  sed 's%{GIF,JPEG,PNG,WEBP}%{PDF,GIF,JPEG,PNG,WEBP}%' new_policy.xml > /etc/ImageMagick-6/policy.xml
# Modify matplotlibversion to kill deprication issues from qiskit. Check necessity upon new qiskit releases
RUN \
  echo "y" | pip --no-cache-dir uninstall matplotlib &&\
  pip --no-cache-dir install matplotlib==3.3.4
# Run the qvm and quilc servers on default ports in case notebook does not call forest_tools.py
# Docker does not recommend run multiple servers in one container, but for now it will have to do
#
# Pick-up the start script for the jupyter-notebook server as the CMD instruction will be overwritten
#
# REmove the workdir
RUN \
  echo "#!/bin/bash" > /usr/local/bin/start_servers.sh &&\
  echo "setsid qvm -S -p 5000 &" >> /usr/local/bin/start_servers.sh &&\
  echo "setsid quilc -R -p 5555 &" >> /usr/local/bin/start_servers.sh &&\
  echo "/usr/local/bin/start-notebook.sh" >> /usr/local/bin/start_servers.sh &&\
  chmod 755 /usr/local/bin/start_servers.sh &&\
  rm -rf ./workdir
CMD ["/usr/local/bin/start_servers.sh"]
