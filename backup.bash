#!/bin/bash
    if [ -z ${1} ]; then
        echo "[---] Ошибка: Первый аргумент - это каталог-дистрибутив."
        exit 1
    fi
    if [ -z ${2} ]; then
        echo "[---] Ошибка: Второй аргумент - это каталог-сервер."
        exit 1
    fi
    if [ -z ${3} ]; then
        echo "[---] Ошибка: Третий аргумент - это каталог-backup."
        exit 1
    fi
    if [[ "$(echo ${1} | tail -c 2)" == "/" ]]; then
        backup_source_location="$(echo ${1} | sed s'/.$//')"
    else
        backup_source_location="${1}"
    fi
    if [[ "$(echo ${2} | tail -c 2)" == "/" ]]; then
        backup_target_location="$(echo ${2} | sed s'/.$//')"
    else
        backup_target_location="${2}"
    fi
    if [[ "$(echo ${3} | tail -c 2)" == "/" ]]; then
        backup_backup_target_location="$(echo ${3} | sed s'/.$//')"
    else
        backup_backup_target_location="${3}"
    fi
    if [[ ! -d "${backup_source_location}" ]]; then
        echo "[---] Ошибка: ${backup_source_location} - это не каталог"
        exit 1
    fi
    if [[ ! -d "${backup_target_location}" ]]; then
        echo "[---] Ошибка: ${backup_target_location} - это не каталог"
        exit 1
    fi
    if [[ ! -d "${backup_backup_target_location}" ]]; then
        echo "[---] Ошибка: ${backup_backup_target_location} - это не каталог"
        exit 1
    fi
    backup_source_list="${backup_source_location}/source.list"
    backup_target_list="${backup_target_location}/target.list"
    backup_title=`echo -n ${backup_source_location} | sed 's|.*/||';echo -n _;echo ${backup_target_location} | sed 's|.*/||';`
    pids_list="$(ps ax | grep SCREEN | grep -v grep | grep ${backup_title}_backup | awk '{print $1}')"
    if [ -n "${pids_list}" ]; then
        echo -n "[---] Внимание: Найдено незавершенное резервирование данных. Завершение..."
        kill -9 ${pids_list}
        if [ "$?" -eq 0 ]; then
            echo " OK"
        else
            echo " FAIL ($?)"
        fi
        screen -wipe > /dev/null 2>&1
    fi
    if [[ "${backup_source_location}" == "${backup_target_location}" ]]; then
        echo "[---] Ошибка: Каталог-дистрибутив не должен совпадать с каталогом-назначением."
        exit 1
    fi
    if [[ ! -d "${backup_source_location}" ]]; then
        echo "[---] Ошибка: Каталог ${backup_source_location} отсутствует."
        exit 1
    fi
    if [[ ! -d "${backup_source_location}" ]]; then
        echo "[---] Ошибка: Каталог ${backup_source_location} отсутствует."
        exit 1
    fi
    cd ${backup_source_location}
    if [ -f "${backup_source_list}" ]; then
        echo -n "[---] Внимание: Найден временный файл от предыдущего резервирования данных (${backup_source_list}). Удаление..."
        rm ${backup_source_list}
        if [ "$?" -eq 0 ]; then
            echo " OK"
        else
            echo " FAIL ($?)"
        fi
    fi
    if [ -f "${backup_target_list}" ]; then
        echo -n "[---] Внимание: Найден временный файл от предыдущего резервирования данных (${backup_target_list}). Удаление..."
        rm ${backup_target_list}
        if [ "$?" -eq 0 ]; then
            echo " OK"
        else
            echo " FAIL ($?)"
        fi
    fi
    find . -type f -print | sed -e 's/^.\{1\}//' > ${backup_source_list}
    find ${backup_target_location} -type f -print > ${backup_target_list}
    if [ -f "${backup_target_list}.backup.part1" ]; then
        echo -n "[---] Внимание: Найден временный файл от предыдущего резервирования данных (${backup_target_list}.backup.part1). Удаление..."
        rm ${backup_target_list}.backup.part1
        if [ "$?" -eq 0 ]; then
            echo " OK"
        else
            echo " FAIL ($?)"
        fi
    fi
    if [ -f "${backup_target_list}.backup.part2" ]; then
        echo -n "[---] Внимание: Найден временный файл от предыдущего резервирования данных (${backup_target_list}.backup.part2). Удаление..."
        rm ${backup_target_list}.backup.part2
        if [ "$?" -eq 0 ]; then
            echo " OK"
        else
            echo " FAIL ($?)"
        fi
    fi
    cp ${backup_target_list} ${backup_target_list}.backup.part1
    index="0"
    for i in $(grep -v ^# $backup_source_list); do
        if [ -f "${backup_target_location}${i}" ]; then
            if [ "$(md5sum ${backup_target_location}${i} | awk '{ print $1 }')" == "$(md5sum ${backup_source_location}${i} | awk '{ print $1 }')" ]; then
                if [ "${index}" -eq "0" ]; then
                    grep -v ${i} ${backup_target_list}.backup.part1 > ${backup_target_list}.backup.part2
                    index="1"
                else
                    grep -v ${i} ${backup_target_list}.backup.part2 > ${backup_target_list}.backup.part1
                    index="0"
                fi
                echo "${i} идентичен оригиналу"
            else
                echo "${i} не идентичен оригиналу"
            fi
        else
            echo "${i} не существует"
        fi
    done
    backup_temp_list=".backup.tar.gz .backup.part1 .backup.part2"
    for i in ${backup_temp_list}; do
        if [ "${index}" -eq "0" ]; then
            grep -v ${i} ${backup_target_list}.backup.part1 > ${backup_target_list}.backup.part2
            index="1"
        else
            grep -v ${i} ${backup_target_list}.backup.part2 > ${backup_target_list}.backup.part1
            index="0"
        fi
    done
    if [ "${index}" -eq "0" ]; then
        backup_target_file="${backup_target_list}.backup.part1"
    else
        backup_target_file="${backup_target_list}.backup.part2"
    fi
    echo "[---] Обработка файлов завершена. Подготовка к резервации данных..."
    if [ -f "${backup_target_list}" ]; then
        echo -n "[---] Внимание: Найден временный файл от резервирования данных (${backup_target_list}). Удаление..."
        rm ${backup_target_list}
        if [ "$?" -eq 0 ]; then
            echo " OK"
        else
            echo " FAIL ($?)"
        fi
    fi
    cp ${backup_target_file} ${backup_target_list}
    if [ "$?" -eq 0 ]; then
        echo "[---] Лист файлов для резервирования (${backup_target_list}) подготовлен."
    else
        echo "[---] Ошибка: Лист файлов для резервирования (${backup_target_list}) не был подготовлен."
        exit 1
    fi
    if [ -f "${backup_target_list}.backup.part1" ]; then
        echo -n "[---] Внимание: Найден временный файл от резервирования данных (${backup_target_list}.backup.part1). Удаление..."
        rm ${backup_target_list}.backup.part1
        if [ "$?" -eq 0 ]; then
            echo " OK"
        else
            echo " FAIL ($?)"
        fi
    fi
    if [ -f "${backup_target_list}.backup.part2" ]; then
        echo -n "[---] Внимание: Найден временный файл от резервирования данных (${backup_target_list}.backup.part2). Удаление..."
        rm ${backup_target_list}.backup.part2
        if [ "$?" -eq 0 ]; then
            echo " OK"
        else
            echo " FAIL ($?)"
        fi
    fi
    echo -n "[---] Подготовка к резервации данных завершена. Процесс резервации данных будет запущен в окне (${backup_title}_backup). Запуск..."
    screen -AmdS ${backup_title}_backup tar -zcf ${backup_backup_target_location}/$(date +%F)_${backup_title}.backup.tar.gz --files-from ${backup_target_list}
    if [ "$?" -eq 0 ]; then
        echo " OK"
    else
        echo " FAIL ($?)"
    fi
    backup_tar_screen_pid=`screen -list | grep ${backup_title}_backup | cut -f1 -d'.' | sed 's/\W//g'`
    if [ -n "${backup_tar_screen_pid}" ]; then
        echo "[---] Для просмотра процесса резервации данных введите: screen -r ${backup_tar_screen_pid}"
    fi