# 不同操作系统，Dockerfile 略有不同
# do component build
bash $RPM_SOURCE_DIR/do-component-build
# cp binary package
cp %{spark_name}-%{spark_base_version}.tar.gz ./
# 规范安装目录
bash $RPM_SOURCE_DIR/install_spark.sh \
          --build-dir=`pwd`         \
          --source-dir=$RPM_SOURCE_DIR \
          --prefix=$RPM_BUILD_ROOT  \
          --doc-dir=%{doc_spark} \
          --lib-dir=%{usr_lib_spark} \
          --var-dir=%{var_lib_spark} \
          --bin-dir=%{bin_dir} \
          --man-dir=%{man_dir} \
          --etc-default=%{etc_default} \
          --etc-spark=%{etc_spark}
# build dockerfile && push to hetucloud docker hub
