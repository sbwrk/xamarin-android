FROM fedora:27
MAINTAINER Claudiu Chiticariu Constatin <chiticariu@gmail.com>, Sascha Müllner <sascha.muellner@gmail.com>

ENV XAMARIN_OSS_BUILD_ID=43659

RUN dnf install gnupg wget dnf-plugins-core -y  \
	&& rpm --import "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF" \
	&& dnf config-manager --add-repo http://download.mono-project.com/repo/centos7/ \
        && dnf install libzip bzip2 bzip2-libs mono-devel nuget msbuild referenceassemblies-pcl lynx -y \
        && dnf clean all

RUN dnf install curl unzip java-1.8.0-openjdk-headless java-1.8.0-openjdk-devel -y && \
    dnf clean all

RUN mkdir -p /android/sdk && \
    curl -k https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip -o sdk-tools-linux-3859397.zip && \
    unzip -q sdk-tools-linux-3859397.zip -d /android/sdk && \
    rm sdk-tools-linux-3859397.zip && \
    ls
    
RUN cd /android/sdk && \
    ls && \
    yes | ./tools/bin/sdkmanager --licenses

RUN cd /android/sdk && \
    ./tools/bin/sdkmanager 'build-tools;30.0.2' 'build-tools;29.0.2' platform-tools 'platforms;android-30' 'platforms;android-29' 'ndk-bundle'


RUN curl -k "https://dev.azure.com/xamarin/public/_apis/build/builds/$XAMARIN_OSS_BUILD_ID/artifacts?artifactName=Installers%20-%20Linux&api-version=5.1" | curl -L $(jq -r '.resource.downloadUrl') -o xamarin-linux.zip && \
    unzip -q xamarin-linux.zip -d /tmp/xamarin-linux && \
    rm xamarin-linux.zip && \
    cd "/tmp/xamarin-linux/Installers - Linux/" && \
    tar xjf ./xamarin.android-oss-v*.tar.bz2 --strip 1 -C /xamarin && \
    cp -a /xamarin/bin/Release/lib/xamarin.android/. /usr/lib/xamarin.android/ && \
    rm -rf /usr/lib/mono/xbuild/Xamarin/Android && \
    rm -rf /usr/lib/mono/xbuild-frameworks/MonoAndroid && \
    ln -s /usr/lib/xamarin.android/xbuild/Xamarin/Android/ /usr/lib/mono/xbuild/Xamarin/Android && \
    ln -s /usr/lib/xamarin.android/xbuild-frameworks/MonoAndroid/ /usr/lib/mono/xbuild-frameworks/MonoAndroid && \
    ln -s /usr/lib/x86_64-linux-gnu/libzip.so.5.0 /usr/lib/x86_64-linux-gnu/libzip.so.4 && \
    rm -rf /tmp/xamarin-linux

# RUN lynx -listonly -dump https://jenkins.mono-project.com/view/Xamarin.Android/job/xamarin-android-linux/lastSuccessfulBuild/Azure/ | grep -o "https://.*/Azure/processDownloadRequest/xamarin-android/xamarin.android-oss_v.*-Release.tar.bz2" > link.txt && \
#     curl -L $(cat link.txt) \
#         -o xamarin.tar.bz2 && \
#     bzip2 -cd xamarin.tar.bz2 | tar -xvf - && \
#     mv xamarin.android-oss_v* /android/xamarin && \
#     ln -s /android/xamarin/bin/Release/lib/xamarin.android/xbuild/Xamarin /usr/lib/mono/xbuild/Xamarin && \
#     ln -s /android/xamarin/bin/Release/lib/xamarin.android/xbuild-frameworks/MonoAndroid/ /usr/lib/mono/xbuild-frameworks/MonoAndroid && \
#     ln -s /usr/lib64/libzip.so.5 /usr/lib64/libzip.so.4 && \
#     rm xamarin.tar.bz2
    
ENV ANDROID_NDK_PATH=/android/sdk/ndk-bundle
ENV ANDROID_HOME=/android/sdk/
ENV PATH=/android/xamarin/bin/Debug/bin:$PATH
ENV JAVA_HOME=/usr/lib/jvm/java/

