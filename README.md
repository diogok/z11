# Z11

A X11 client library in Zig.

It has no dependencies and uses just Zig.

It is based on the material on the [docs](/docs) folder and reading [libx11 source](https://gitlab.freedesktop.org/xorg/lib/libx11).

It is incomplete, missing specially:
- Extension support
- There is no queue for messages
- Some requests still missing from the proto

But it seems to work.

For usage checkout the [documentation](https://diogok.github.io/z11) or the commented [src/demo.zig](src/demo.zig).

## License

MIT