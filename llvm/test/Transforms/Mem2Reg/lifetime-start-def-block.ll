; RUN: opt -passes=mem2reg -S %s | FileCheck %s
; RUN: opt -passes=sroa -S %s | FileCheck %s

declare void @llvm.lifetime.start.p0(ptr nocapture)
declare void @llvm.lifetime.end.p0(ptr nocapture)
declare void @use(i32)

define void @direct(i1 %should_store, i1 %store_a, i32 %a, i32 %b) {
; CHECK-LABEL: define void @direct(
entry:
  %slot = alloca i32
  br label %loop

loop:
; CHECK:       loop:
; CHECK-NOT:     phi
  call void @llvm.lifetime.start.p0(ptr %slot)
  br i1 %should_store, label %select.store, label %join

select.store:
  br i1 %store_a, label %store.a, label %store.b

store.a:
  store i32 %a, ptr %slot
  br label %join

store.b:
  store i32 %b, ptr %slot
  br label %join

join:
; CHECK:       join:
; CHECK-NEXT:    [[VALUE:%.*]] = phi i32 [ %a, %store.a ], [ %b, %store.b ], [ undef, %loop ]
; CHECK-NEXT:    call void @use(i32 [[VALUE]])
  %value = load i32, ptr %slot
  call void @use(i32 %value)
  call void @llvm.lifetime.end.p0(ptr %slot)
  br label %loop
}
