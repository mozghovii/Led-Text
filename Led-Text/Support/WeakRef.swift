public final class WeakRef<T: AnyObject> {
    weak var object: T?

    init(object: T?) {
        self.object = object
    }
}
