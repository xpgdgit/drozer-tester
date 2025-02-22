#!/bin/expect

#
##set package_name "jakhar.aseem.diva"
# exp_internal 1
set timeout -1
exec rm -f ./drozer-tester/drozer-tester.log
exec mkdir -p ./drozer-tester/ 
exec touch  -f ./drozer-tester/drozer-tester.log

log_file "./drozer-tester/drozer-tester.log"
set result_file "./drozer-tester/drozer-tester.log"
set isConnect "0"



proc printLogo {} {
    puts "\033\[34m"
    puts " ______  ______  _____             _               "
    puts " |  _  \\|___  / |_   _|           | |              "
    puts " | | | |   / /    | |    ___  ___ | |_   ___  _ __ "
    puts " | | | |  / /     | |   / _ \\/ __|| __| / _ \\| '__|"
    puts " | |/ / ./ /___   | |  |  __/\\__ \\| |_ |  __/| |   "
    puts " |___/  \\_____/   \\_/   \\___||___/ \\__| \\___||_|   "
    puts "                                                   "
    puts " \033\[1m"
    puts {                                      @Javeley        }
    puts {                                      github: https://github.com/JaveleyQAQ/drozer-tester}
    puts "\033\[0m"
}

proc forward_adb {} {
 
    if {[catch {set port [exec lsof -i:31415 | grep adb | wc -l]} result]} {
        puts "\033\[31m\[-\] 没有转发drozer默认31415端口\033\[0m"
        set port 0
        #puts "$result"
    }
    if {$port == 0} {   
    #    catch {exec adb forward tcp:31415 tcp:31415}
       exec adb forward tcp:31415 tcp:31415
       puts "\033\[31m\[-\] 正在开启31415端口转发 adb forward tcp:31415 tcp:31415 \033\[0m"
    }
}
# 调用打印logo的函数
printLogo
forward_adb 


proc scan_app {package_name} {
    global isConnect

    if {$isConnect == 0} {
        spawn drozer console connect
        expect {
            "drozer Console" {
                set isConnect 1
            }
            "drozer Server running?" {
               puts "\033\[31m\[\-\] drozer 连接失败，请手动检查是adb/drozer否可连接！\033\[0m"
                exit 1
            }
        }
    }

    set surface   "run app.package.attacksurface $package_name"
    set finduris  "run scanner.provider.finduris -a $package_name"
    set injection "run scanner.provider.injection -a $package_name"
    set sqltables "run scanner.provider.sqltables -a $package_name"
    set traversal "run scanner.provider.traversal -a $package_name"
    set activity  "run app.activity.info -a $package_name"
    set service   "run app.service.info -a $package_name"

   

    puts "\033\[32m\[\+\]正在扫描 $package_name \033\[0m"

    expect "dz>"
    puts  "\033\[32m\[\+\]  查看 $package_name 攻击面 \r\033\[0m "
    send "$surface \r"

    expect "dz>"
    puts  "\033\[32m\[\+\] 扫描 $package_name finduri\r\033\[0m"
    send "$finduris \r"

    expect "dz>"
    puts  "\033\[32m\[\+\] 扫描 $package_name sqltables \r \033\[0m"
    send "$sqltables \r"

    expect "dz>"
    puts  "\033\[32m\[\+\] 扫描 $package_name 路径遍历\r \033\[0m"
    send "$traversal \r "



    expect "dz>" 
    puts  "\033\[32m\[\+\] 扫描 $package_name 暴露activity \r\033\[0m"
    send "$activity \r "

        
    expect "dz>" {
            global  result_file
            # 修改为匹配到Permission: null的前一行
            set activity_names [exec cat ${result_file} | sed -n "/Permission: null/{x;p;d;}; x" | sort | uniq ]
             
            # puts " \033\[32m\[\+\] 显示activity $activity_names  \033\[0m"

            set lines [split $activity_names "\n"]

       
            if {[llength $lines] > 0} {
                # 创建activity启动截图保存路径
                exec mkdir -p ./drozer-tester/${package_name}
                puts ""
                puts  " \033\[32m\[\+\] 正在尝试启动暴露的activity，请稍等 \033\[0m"
                
                foreach activity_name $lines {
                    # puts "Line: $activity_name"
                    set trimmed_activity_name [string trim $activity_name] 
                    set screenshot_file "tmp/$trimmed_activity_name.png"
                
                    
                    expect "" {
                        send  "run   app.activity.start   --component $package_name $trimmed_activity_name \r"
                        puts  "\033\[32m run   app.activity.start   --component $package_name $trimmed_activity_name \r \033\[0m"
                        sleep 1
                        exec   adb  shell screencap -p /sdcard/$screenshot_file
                        exec   adb  shell screencap -p /sdcard/tmp/$trimmed_activity_name.png
                        exec   adb  pull /sdcard/tmp/$trimmed_activity_name.png   ./drozer-tester/${package_name}/
                    }
                    
        
                }
                puts ""
                puts "\033\[32m\[\+\]\[$package_name\] 扫描完成，请查看 \033\[0m"
                puts ""
            } else {
                puts ""
                puts "\033\[31m\[-\] 没有找到暴露的activity. 可能匹配规则遗漏，运行$activity 自查 \033\[0m"
                
            }
    }
    
    # expect "dz>"
    # puts  "\033\[32m\[\+\] 扫描 $package_name 暴露service \r\033\[0m"
    # send "$service \r "

    # expect "dz>" {
    #         global  result_file
    #         # 修改为匹配到Permission: null的前一行
    #         set service_names [exec cat ${result_file} | sed -n "/Permission: null/{x;p;d;}; x" | sort | uniq ]
             
    #         puts " \033\[32m\[\+\] 显示service $service_names  \033\[0m"

    #         set lines [split $service_names "\n"]

       
    #         if {[llength $lines] > 0} {
    #             # 创建service启动截图保存路径
    #             exec mkdir -p ./drozer-tester/${package_name}
    #             puts ""
    #             puts  " \033\[32m\[\+\] 正在尝试启动暴露的service，请稍等 \033\[0m"
                
    #             foreach service_name $lines {
    #                 # puts "Line: $activity_name"
    #                 set trimmed_service_name [string trim $service_name] 
    #                 set screenshot_file "tmp/$trimmed_service_name.png"
                
                    
    #                 expect "" {
    #                     send  "run   app.service.start --action $trimmed_service_name --component $package_name $trimmed_service_name \r"
    #                     puts  "\033\[32m run   app.service.start  --action $trimmed_service_name --component $package_name $trimmed_service_name \r \033\[0m"
    #                     sleep 1
    #                     exec   adb  shell screencap -p '/sdcard/$screenshot_file'
    #                     exec   adb  shell screencap -p '/sdcard/tmp/$trimmed_service_name.png'
    #                     exec   adb  pull /sdcard/tmp/$trimmed_service_name.png   ./drozer-tester/${package_name}/
    #                 }
                    
        
    #             }
    #             puts ""
    #             puts "\033\[32m\[\+\]\[$package_name\] 扫描完成，请查看 \033\[0m"
    #             puts ""
    #         } else {
    #             puts ""
    #             puts "\033\[31m\[-\] 没有找到暴露的service. 可能匹配规则遗漏，运行$service 自查 \033\[0m"
                
    #         }
    # }

}





if {$argc < 1} {
    puts "请提供要扫描的程序包名作为参数" 
    puts ""
    puts "  \033\[35mExample:" 
    puts "                  \[1\] expect drozer-tester.sh jakhar.aseem.diva"
    puts "                  \[2\] ./drozer-tester.sh jakhar.aseem.diva\033\[0m   "
    puts "             "
    puts "  -all/all        扫描所有应用程序"
    puts ""
    exit 1
}



    set package_name [lindex $argv 0]
    scan_app $package_name
    global  result_file
    puts ""
    puts "\033\[1m\033\[32m\[\+\]运行日志文件为$result_file \033\[1m "
    puts ""

