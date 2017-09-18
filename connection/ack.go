package connection

import (
	"sync"

	"github.com/VolantMQ/volantmq/packet"
)

type onRelease func(o, n packet.Provider)

type ackQueue struct {
	messages  sync.Map
	onRelease onRelease
}

func newAckQueue(cb onRelease) *ackQueue {
	a := ackQueue{
		onRelease: cb,
	}

	return &a
}

func (a *ackQueue) store(pkt packet.Provider) {
	id, _ := pkt.ID()
	a.messages.Store(id, pkt)
}

func (a *ackQueue) release(pkt packet.Provider) {
	id, _ := pkt.ID()

	if value, ok := a.messages.Load(id); ok {
		if orig, ok := value.(packet.Provider); ok && a.onRelease != nil {
			a.onRelease(orig, pkt)
		}
		a.messages.Delete(id)
	}
}

//func (a *ackQueue) wipe() {
//	a.lock.Lock()
//	defer a.lock.Unlock()
//
//	a.messages = make(map[message.IDType]message.Provider)
//}