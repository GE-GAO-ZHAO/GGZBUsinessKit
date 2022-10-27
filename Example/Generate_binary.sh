
#!/bin/sh

# 参数
workspace="GGZBUsinessKit"
scheme="GGZBUsinessKit"
project_name=${scheme}
framework_name=${scheme}
build_dir="build"
out_dir="out"
final_framework_dir="../GGZBUsinessKit/Frameworks"

# 清除缓存
function build_clean {
    echo "======build_clean start======"

    rm -rf ${build_dir}
    rm -rf ${out_dir}
    
    echo "======build_clean end======"
}

# 配置
function build_config {
    echo "======build_config start======"

    # build版本号：日期
    build_version=`date +%y%m%d%H%M%S`
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${build_version}" ./${project_name}/${framework_name}/info.plist

    # build版本号：自增
    # build_version=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "./${project_name}/${framework_name}/info.plist" )

    # build_version=$(($build_version + 1))
    # /usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${build_version}" ./${project_name}/${framework_name}/info.plist
    echo "======build_config end======"
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

# 调用
build_clean
build_config
build_framework
build_fat_framework
store_final_framework
