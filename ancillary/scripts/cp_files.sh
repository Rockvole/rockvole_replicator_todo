#! /bin/bash
src_dao_loc=/work/projects/dart/rockvole_db/test/lib/dao
dst_dao_loc=../../lib/dao

src_schema_loc=/work/projects/dart/rockvole_db/ancillary
dst_schema_loc=../../ancillary

mkdir -p $dst_dao_loc
cp $src_dao_loc/TaskDao.dart $dst_dao_loc
cp $src_dao_loc/TaskMixin.dart $dst_dao_loc

mkdir -p $dst_schema_loc
cp $src_schema_loc/todo_schema.yaml $dst_schema_loc

