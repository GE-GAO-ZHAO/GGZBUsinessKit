
#!/bin/sh

# 参数
workspace="GGZBUsinessKit"
scheme="GGZBUsinessKit"
project_name=${scheme}
framework_name=${scheme}
pod_source_name=${scheme}
pod_binary_name="GGZBUsinessKit-binary"
build_dir="build"
out_dir="out"
final_framework_dir="../GGZBUsinessKit/Frameworks"
old_build_version=""
build_version=""

# 清除缓存
function build_clean {
    echo "======build_clean start======"
    
    rm -rf ${build_dir}
    rm -rf ${out_dir}
    
    echo "======build_clean end======"
}

# 编译
function build_framework {
    echo "======build_framework start======"
    
    #若支持bitCode，需加参数：-fembed-bitcode
    xcodebuild -workspace ${workspace}.xcworkspace -scheme ${scheme} -sdk iphoneos -configuration "Release" OTHER_CFLAGS="-fembed-bitcode" BUILD_DIR="../${build_dir}" build || exit 1
    
    xcodebuild -workspace ${workspace}.xcworkspace -scheme ${scheme} -sdk iphonesimulator -configuration "Release" OTHER_CFLAGS="-fembed-bitcode" BUILD_DIR="../${build_dir}" build || exit 1
    
    #删除模拟器arm64架构
    cd /Users/gegaozhao/Desktop/person/工程化1/GGZBUsinessKit/Example/build/Release-iphonesimulator/GGZBUsinessKit/GGZBUsinessKit.framework
    
    lipo -remove arm64 ${framework_name} -o ${framework_name}
    cd ../../../../
    CURRENT_DIR=$(cd $(dirname $0); pwd)
    
    echo "======build_framework end======"
}

# 合并
function build_fat_framework {
    echo "======build_fat_framework start======"
    
    mkdir -p ${out_dir}/
    
    cp -R ${build_dir}/Release-iphoneos/${framework_name}/${framework_name}.framework ${out_dir}
    
    lipo -create ${build_dir}/Release-iphonesimulator/${framework_name}/${framework_name}.framework/${framework_name} ${build_dir}/Release-iphoneos/${framework_name}/${framework_name}.framework/${framework_name} -output ${out_dir}/${framework_name}.framework/${framework_name} || exit 1
    echo "======build_fat_framework end======"
}

# 将最终的二进制库转移到最终目录下
function store_final_framework {
    echo "======build final framework start======"
    if [ -d ${final_framework_dir} ];then
    echo "删除 ${final_framework_dir}"
    rm -R ${final_framework_dir}
    fi
    echo "创建 ${final_framework_dir}"
    mkdir ${final_framework_dir}
    cp -R ${out_dir}/${framework_name}.framework ${final_framework_dir}
    echo "======build final framework end======"
}

# 获取新版本
function obtain_new_version {
    echo "======obtain_new_version start======"
    echo "======obtain_new_version   end======"
}

# 配置podspec版本号
function podspec_verion_config {
    echo "======build_config start======"
    old_build_version=`grep -E 's.version.*=' ../GGZBUsinessKit.podspec | tr -d "'a-z= " | sed "s/\.//1"`
    echo "old version is: ${old_build_version}"
    increment_version $old_build_version
    replae_podspec_version
    echo "======build_config end======"
}
function increment_version {
    declare -a part=( ${1//\./ } )
    declare    new
    declare -i carry=1
    CNTR=${#part[@]}-1
    len=${#part[CNTR]}
    new=$((part[CNTR]+carry))
    part[CNTR]=${new}
    build_version="${part[*]}"
    echo "new version is: ${build_version// /.}"
}
function replae_podspec_version {
    echo "最新版本:${build_version// /.}"
    new="${build_version// /.}"
    python3 ../increase_version_podspec.py "../${pod_source_name}.podspec" "${new}"
    python3 ../increase_version_podspec.py "../${pod_binary_name}.podspec" "${new}"
    #sed -i '' -e 's/'  s.version          = ''"$old"'''/'  s.version          = '"$new"''/g' "${pod_source_name}.podspec"
    #sed -i '' -e "s/  s.version          = '${old_build_version}'/  s.version          = '${build_version// /.}'/g" "${pod_binary_name}.podspec"
}

# 检测是否需要提交信息 && 有的话就进行提交远程仓库 && 打tag提交到远程
function detect_code_commit {
    echo "======detect_code_commit start======"
    git add *
    git commit -m '提交静态库和更新后的代码逻辑'
    git push --set-upstream origin
    echo "======detect_code_commit start======"
}

# 打tag
function push_new_tag {
    echo "======add_new_tag start======"
    git tag "${build_version// /.}"
    git push origin --tags
    echo "======add_new_tag end  ======"
}

# pod发布
function pod_release_publish {
    cd ../
    echo "======pod source publish start======"
    pod repo push GGZSpec ${pod_source_name}.podspec --use-libraries --allow-warnings --skip-import-validation --skip-tests --verbose
    echo "======pod source publish end======"
    
    echo "======pod binary publish start======"
    pod repo push GGZSpec ${pod_binary_name}.podspec --use-libraries --allow-warnings --skip-import-validation --skip-tests --verbose
    echo "======pod binary publish end======"
}

# =========== 调用逻辑 start =========== #

#步骤1: 打静态库
build_clean
build_framework
build_fat_framework
store_final_framework

#步骤2: 修改podspec版本号
podspec_verion_config

#步骤3: 提交修改信息和静态库
detect_code_commit

#步骤4: 打tag并提交tags
push_new_tag

#步骤5: pod发布源码库和二进制库
pod_release_publish

# =========== 调用逻辑 end =========== #

